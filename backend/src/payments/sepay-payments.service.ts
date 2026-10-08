import { ConflictException, ForbiddenException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource, EntityManager } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PaymentStatus } from '../common/enums/payment-status.enum';
import { centsToMoney, moneyToCents } from '../common/utils/money';
import { MatchingService } from '../orders/matching.service';
import { Order } from '../orders/order.entity';
import { RealtimePublisher } from '../realtime/realtime-publisher.port';
import { BankTransferGateway } from './application/bank-transfer.gateway';
import { SepayWebhookDto } from './dto/sepay.dto';
import { Payment } from './payment.entity';
import { SepayWebhookEvent, SepayWebhookOutcome } from './sepay-webhook-event.entity';

@Injectable()
export class SepayPaymentsService {
  constructor(
    private readonly database: DataSource,
    private readonly config: ConfigService,
    private readonly gateway: BankTransferGateway,
    private readonly matching: MatchingService,
    @Optional() private readonly realtime?: RealtimePublisher,
  ) {}

  async instructions(orderId: number, customerId: number) {
    this.assertEnabled();
    const payment = await this.database.getRepository(Payment).findOne({
      where: { orderId },
      relations: { order: true },
      order: { id: 'ASC' },
    });
    if (!payment || payment.order.customerId !== customerId) throw new NotFoundException('Order not found');
    if (payment.status !== PaymentStatus.PENDING || payment.order.status !== OrderStatus.AWAITING_PREPAYMENT) {
      throw new ConflictException('Order is not awaiting bank-transfer prepayment');
    }
    return this.gateway.createInstructions({
      paymentId: payment.id,
      amount: payment.amount,
    });
  }

  async receive(
    payload: SepayWebhookDto,
    rawBody: Buffer | undefined,
    timestamp: string | undefined,
    signature: string | undefined,
  ): Promise<{ success: true }> {
    this.assertEnabled();
    const payloadSha256 = this.gateway.verifyWebhook({
      rawBody,
      timestamp,
      signature,
    });
    const result = await this.database.transaction(async (manager) => {
      const externalTransactionId = String(payload.id);
      await manager.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [externalTransactionId]);
      const existing = await manager.getRepository(SepayWebhookEvent).findOneBy({ externalTransactionId });
      if (existing) {
        if (existing.payloadSha256 !== payloadSha256) {
          throw new ConflictException('Webhook transaction payload changed');
        }
        return {
          changed: false,
          orderId: null,
          status: null,
          offer: null,
        };
      }

      if (!this.matchesConfiguredAccount(payload)) {
        await this.audit(manager, payload, payloadSha256, null, 'IGNORED_ACCOUNT');
        return { changed: false, orderId: null, status: null, offer: null };
      }
      if (payload.transferType !== 'in') {
        await this.audit(manager, payload, payloadSha256, null, 'IGNORED_DIRECTION');
        return { changed: false, orderId: null, status: null, offer: null };
      }

      const paymentId = this.paymentIdFromCode(payload.code);
      if (paymentId === null) {
        await this.audit(manager, payload, payloadSha256, null, 'IGNORED_PAYMENT_CODE');
        return { changed: false, orderId: null, status: null, offer: null };
      }
      const paymentSnapshot = await manager.getRepository(Payment).findOneBy({ id: paymentId });
      if (!paymentSnapshot) {
        await this.audit(manager, payload, payloadSha256, null, 'PAYMENT_NOT_FOUND');
        return { changed: false, orderId: null, status: null, offer: null };
      }

      // All order/payment workflows lock in this order to avoid deadlocks with
      // cancellation, refund and demo-settlement transactions.
      const order = await manager.getRepository(Order).findOne({
        where: { id: paymentSnapshot.orderId },
        lock: { mode: 'pessimistic_write' },
      });
      const payment = await manager.getRepository(Payment).findOne({
        where: { id: paymentId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!payment || !order) {
        await this.audit(manager, payload, payloadSha256, payment?.id ?? null, 'PAYMENT_NOT_FOUND');
        return { changed: false, orderId: null, status: null, offer: null };
      }
      if (moneyToCents(payment.amount) !== BigInt(payload.transferAmount) * 100n) {
        await this.audit(manager, payload, payloadSha256, payment.id, 'AMOUNT_MISMATCH');
        return {
          changed: false,
          orderId: payment.orderId,
          status: null,
          offer: null,
        };
      }
      if (payment.status !== PaymentStatus.PENDING) {
        await this.audit(manager, payload, payloadSha256, payment.id, 'PAYMENT_NOT_PENDING');
        return {
          changed: false,
          orderId: payment.orderId,
          status: null,
          offer: null,
        };
      }

      if (order.status !== OrderStatus.AWAITING_PREPAYMENT) {
        await this.audit(manager, payload, payloadSha256, payment.id, 'PAYMENT_NOT_PENDING');
        return {
          changed: false,
          orderId: payment.orderId,
          status: null,
          offer: null,
        };
      }

      payment.status = PaymentStatus.PAID;
      payment.isDemo = false;
      payment.paidAt = new Date();
      payment.sepayTransactionId = externalTransactionId;
      await manager.getRepository(Payment).save(payment);
      order.status = OrderStatus.PENDING_MATCH;
      await manager.getRepository(Order).save(order);
      const offer = await this.matching.matchLockedOrder(manager, order);
      await this.audit(manager, payload, payloadSha256, payment.id, 'APPLIED');
      return { changed: true, orderId: order.id, status: order.status, offer };
    });

    if (result.changed && result.orderId && result.status) {
      this.realtime?.orderStatusChanged(result.orderId, result.status);
      if (result.offer) {
        this.realtime?.offerCreated(result.offer.providerId, result.orderId, result.offer.id, result.offer.expiresAt);
      }
    }
    return { success: true };
  }

  private assertEnabled(): void {
    if (!this.config.get<boolean>('SEPAY_ENABLED')) {
      throw new ForbiddenException('SePay Test mode is disabled');
    }
    if (this.config.get<string>('SEPAY_MODE') !== 'test') {
      throw new ForbiddenException('Only SePay Test mode is supported');
    }
  }

  private matchesConfiguredAccount(payload: SepayWebhookDto): boolean {
    const expected = this.config.getOrThrow<string>('SEPAY_ACCOUNT_NUMBER');
    return payload.accountNumber === expected || payload.subAccount === expected;
  }

  private paymentIdFromCode(code: string | null): number | null {
    if (!code) return null;
    const prefix = this.config.getOrThrow<string>('SEPAY_PAYMENT_CODE_PREFIX');
    const match = new RegExp(`^${prefix}(\\d+)$`, 'i').exec(code.trim());
    if (!match) return null;
    const paymentId = Number(match[1]);
    return Number.isSafeInteger(paymentId) && paymentId > 0 ? paymentId : null;
  }

  private async audit(
    manager: EntityManager,
    payload: SepayWebhookDto,
    payloadSha256: string,
    paymentId: number | null,
    outcome: SepayWebhookOutcome,
  ): Promise<void> {
    await manager.getRepository(SepayWebhookEvent).save(
      manager.getRepository(SepayWebhookEvent).create({
        externalTransactionId: String(payload.id),
        paymentId,
        paymentCode: payload.code,
        referenceCode: payload.referenceCode || null,
        amount: centsToMoney(BigInt(payload.transferAmount) * 100n),
        payloadSha256,
        outcome,
      }),
    );
  }
}
