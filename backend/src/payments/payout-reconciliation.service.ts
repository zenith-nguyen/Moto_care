import {
  ConflictException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource, EntityManager } from 'typeorm';
import { WithdrawalPayoutStatus } from '../common/enums/withdrawal-payout-status.enum';
import { centsToMoney, moneyToCents } from '../common/utils/money';
import { PayoutReconciliationDecision, ReconcileWithdrawalPayoutDto } from './dto/payout-reconciliation.dto';
import { SepayWebhookDto } from './dto/sepay.dto';
import {
  SepayPayoutWebhookEvent,
  SepayPayoutWebhookOutcome,
} from './sepay-payout-webhook-event.entity';
import { verifySepayWebhook } from './infrastructure/sepay-webhook-auth';
import { WithdrawalPayout } from './withdrawal-payout.entity';
import { WithdrawalRequest } from './withdrawal-request.entity';

@Injectable()
export class PayoutReconciliationService {
  constructor(
    private readonly database: DataSource,
    private readonly config: ConfigService,
  ) {}

  async ensureForApproved(manager: EntityManager, withdrawal: WithdrawalRequest): Promise<WithdrawalPayout> {
    const repository = manager.getRepository(WithdrawalPayout);
    const existing = await repository.findOneBy({ withdrawalId: withdrawal.id });
    if (existing) return existing;
    return repository.save(repository.create({
      withdrawalId: withdrawal.id,
      payoutCode: this.payoutCode(withdrawal.id),
      expectedAmount: withdrawal.amount,
      status: WithdrawalPayoutStatus.AWAITING_TRANSFER,
      externalTransactionId: null,
      externalReferenceCode: null,
      observedAmount: null,
      reviewReason: null,
      reconciledById: null,
      reconciledAt: null,
    }));
  }

  async pending() {
    const items = await this.database.getRepository(WithdrawalPayout)
      .createQueryBuilder('payout')
      .innerJoinAndSelect('payout.withdrawal', 'withdrawal')
      .innerJoinAndSelect('withdrawal.provider', 'provider')
      .innerJoinAndSelect('provider.user', 'user')
      .where('payout.status IN (:...statuses)', {
        statuses: [WithdrawalPayoutStatus.AWAITING_TRANSFER, WithdrawalPayoutStatus.MANUAL_REVIEW],
      })
      .orderBy('payout.createdAt', 'ASC')
      .addOrderBy('payout.id', 'ASC')
      .take(50)
      .getMany();
    return items.map((payout) => ({
      ...this.format(payout),
      provider: {
        id: payout.withdrawal.provider.id,
        userId: payout.withdrawal.provider.userId,
        name: payout.withdrawal.provider.user.name,
      },
    }));
  }

  async reconcile(payoutId: number, adminId: number, dto: ReconcileWithdrawalPayoutDto) {
    return this.database.transaction(async (manager) => {
      const repository = manager.getRepository(WithdrawalPayout);
      const payout = await repository.findOne({
        where: { id: payoutId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!payout) throw new NotFoundException('Withdrawal payout not found');
      if (payout.status === WithdrawalPayoutStatus.RECONCILED) {
        if (dto.decision === PayoutReconciliationDecision.CONFIRM
          && dto.externalTransactionId?.trim() === payout.externalTransactionId) {
          return this.format(payout);
        }
        throw new ConflictException('Withdrawal payout is already reconciled');
      }

      if (dto.decision === PayoutReconciliationDecision.FLAG) {
        payout.status = WithdrawalPayoutStatus.MANUAL_REVIEW;
        payout.reviewReason = dto.reason!.trim();
        await repository.save(payout);
        return this.format(payout);
      }

      if (moneyToCents(dto.observedAmount!) !== moneyToCents(payout.expectedAmount)) {
        throw new ConflictException('Observed bank amount does not match the approved payout');
      }
      const externalTransactionId = dto.externalTransactionId!.trim();
      if (payout.externalTransactionId && payout.externalTransactionId !== externalTransactionId) {
        throw new ConflictException('Payout is already linked to a different bank transaction');
      }
      const transactionUsed = await repository.createQueryBuilder('payout')
        .where('payout.external_transaction_id = :externalTransactionId', { externalTransactionId })
        .andWhere('payout.id <> :payoutId', { payoutId: payout.id })
        .getExists();
      if (transactionUsed) throw new ConflictException('Bank transaction is already linked to another payout');
      payout.status = WithdrawalPayoutStatus.RECONCILED;
      payout.externalTransactionId = externalTransactionId;
      payout.externalReferenceCode = dto.referenceCode?.trim() || null;
      payout.observedAmount = dto.observedAmount!;
      payout.reviewReason = dto.reason?.trim() || 'Recipient and bank receipt verified by Admin';
      payout.reconciledById = adminId;
      payout.reconciledAt = new Date();
      await repository.save(payout);
      return this.format(payout);
    });
  }

  async receive(
    payload: SepayWebhookDto,
    rawBody: Buffer | undefined,
    timestamp: string | undefined,
    signature: string | undefined,
  ) {
    if (!this.config.get<boolean>('SEPAY_PAYOUT_RECONCILIATION_ENABLED')) {
      throw new ServiceUnavailableException('SePay payout reconciliation is disabled');
    }
    const payloadSha256 = verifySepayWebhook({
      rawBody,
      timestamp,
      signature,
      secret: this.config.getOrThrow<string>('SEPAY_PAYOUT_WEBHOOK_SECRET'),
      maxAgeSeconds: this.config.getOrThrow<number>('SEPAY_PAYOUT_WEBHOOK_MAX_AGE_SECONDS'),
    });
    // Keep dashboard probes out of payout reconciliation and its audit log.
    if (payload.id === 0) return { success: true };
    const externalTransactionId = String(payload.id);

    await this.database.transaction(async (manager) => {
      const events = manager.getRepository(SepayPayoutWebhookEvent);
      await manager.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [
        `payout:${externalTransactionId}`,
      ]);
      const existing = await events.findOneBy({ externalTransactionId });
      if (existing) {
        if (existing.payloadSha256 !== payloadSha256) {
          throw new ConflictException('Webhook transaction payload changed');
        }
        return;
      }

      const amount = centsToMoney(BigInt(payload.transferAmount) * 100n);
      if (!this.matchesSourceAccount(payload)) {
        await this.audit(manager, payload, payloadSha256, null, null, amount, 'IGNORED_ACCOUNT');
        return;
      }
      if (payload.transferType !== 'out') {
        await this.audit(manager, payload, payloadSha256, null, null, amount, 'IGNORED_DIRECTION');
        return;
      }
      const payoutCode = this.extractPayoutCode(payload);
      if (!payoutCode) {
        await this.audit(manager, payload, payloadSha256, null, null, amount, 'IGNORED_PAYOUT_CODE');
        return;
      }
      const payouts = manager.getRepository(WithdrawalPayout);
      const payout = await payouts.findOne({
        where: { payoutCode },
        lock: { mode: 'pessimistic_write' },
      });
      if (!payout) {
        await this.audit(manager, payload, payloadSha256, null, payoutCode, amount, 'PAYOUT_NOT_FOUND');
        return;
      }
      if (payout.status === WithdrawalPayoutStatus.RECONCILED) {
        await this.audit(manager, payload, payloadSha256, payout.id, payoutCode, amount, 'ALREADY_RECONCILED');
        return;
      }
      if (payout.externalTransactionId && payout.externalTransactionId !== externalTransactionId) {
        payout.status = WithdrawalPayoutStatus.MANUAL_REVIEW;
        payout.reviewReason = 'Multiple outgoing bank transactions reference the same payout code';
        await payouts.save(payout);
        await this.audit(manager, payload, payloadSha256, payout.id, payoutCode, amount, 'MULTIPLE_TRANSACTIONS');
        return;
      }

      payout.externalTransactionId = externalTransactionId;
      payout.externalReferenceCode = payload.referenceCode || null;
      payout.observedAmount = amount;
      payout.status = WithdrawalPayoutStatus.MANUAL_REVIEW;
      let outcome: SepayPayoutWebhookOutcome = 'MANUAL_REVIEW_REQUIRED';
      if (moneyToCents(amount) !== moneyToCents(payout.expectedAmount)) {
        outcome = 'AMOUNT_MISMATCH';
        payout.reviewReason = 'Observed bank amount differs from the approved payout';
      } else {
        payout.reviewReason = 'Verify recipient and bank receipt before confirming payout';
      }
      await payouts.save(payout);
      await this.audit(manager, payload, payloadSha256, payout.id, payoutCode, amount, outcome);
    });
    return { success: true };
  }

  format(payout: WithdrawalPayout) {
    return {
      id: payout.id,
      withdrawalId: payout.withdrawalId,
      payoutCode: payout.payoutCode,
      expectedAmount: payout.expectedAmount,
      status: payout.status,
      externalTransactionId: payout.externalTransactionId,
      externalReferenceCode: payout.externalReferenceCode,
      observedAmount: payout.observedAmount,
      reviewReason: payout.reviewReason,
      reconciledById: payout.reconciledById,
      reconciledAt: payout.reconciledAt,
      bankTransferConfirmed: payout.status === WithdrawalPayoutStatus.RECONCILED,
      createdAt: payout.createdAt,
      updatedAt: payout.updatedAt,
    };
  }

  private payoutCode(withdrawalId: number): string {
    return `${this.config.get<string>('SEPAY_PAYOUT_CODE_PREFIX', 'RP')}${withdrawalId}`;
  }

  private extractPayoutCode(payload: SepayWebhookDto): string | null {
    const prefix = this.config.get<string>('SEPAY_PAYOUT_CODE_PREFIX', 'RP');
    const escaped = prefix.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const pattern = new RegExp(`(?:^|[^A-Z0-9])(${escaped}\\d+)(?:$|[^A-Z0-9])`, 'i');
    return [payload.code, payload.content, payload.description]
      .filter((value): value is string => Boolean(value))
      .map((value) => value.match(pattern)?.[1]?.toUpperCase())
      .find(Boolean) ?? null;
  }

  private matchesSourceAccount(payload: SepayWebhookDto): boolean {
    const expected = this.config.getOrThrow<string>('SEPAY_PAYOUT_SOURCE_ACCOUNT');
    return [payload.accountNumber, payload.subAccount]
      .filter((value): value is string => Boolean(value))
      .some((value) => value.replace(/\s+/g, '').toUpperCase() === expected.replace(/\s+/g, '').toUpperCase());
  }

  private async audit(
    manager: EntityManager,
    payload: SepayWebhookDto,
    payloadSha256: string,
    payoutId: number | null,
    payoutCode: string | null,
    amount: string,
    outcome: SepayPayoutWebhookOutcome,
  ): Promise<void> {
    const repository = manager.getRepository(SepayPayoutWebhookEvent);
    await repository.save(repository.create({
      externalTransactionId: String(payload.id),
      payoutId,
      payoutCode,
      referenceCode: payload.referenceCode || null,
      amount,
      payloadSha256,
      outcome,
    }));
  }
}
