import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { WalletTransactionType } from '../common/enums/wallet-transaction-type.enum';
import { WithdrawalStatus } from '../common/enums/withdrawal-status.enum';
import { centsToMoney, moneyToCents } from '../common/utils/money';
import { Provider } from '../providers/provider.entity';
import { CreateWithdrawalDto, WithdrawalDecision } from './dto/withdrawal.dto';
import { WalletTransaction } from './wallet-transaction.entity';
import { Wallet } from './wallet.entity';
import { WithdrawalRequest } from './withdrawal-request.entity';

@Injectable()
export class WithdrawalsService {
  constructor(private readonly database: DataSource) {}

  async create(providerUserId: number, dto: CreateWithdrawalDto) {
    return this.database.transaction(async (manager) => {
      const provider = await this.lockProvider(manager, providerUserId);
      const wallet = await this.lockWallet(manager, provider.id);
      const hasPending = await manager.getRepository(WithdrawalRequest).existsBy({
        providerId: provider.id,
        status: WithdrawalStatus.PENDING,
      });
      if (hasPending) throw new ConflictException('Provider already has a pending withdrawal request');
      const amount = moneyToCents(dto.amount);
      const balance = moneyToCents(wallet.balance);
      const locked = moneyToCents(wallet.lockedBalance);
      if (amount <= 0n || amount > balance - locked) {
        throw new ConflictException('Withdrawal amount exceeds available demo balance');
      }
      wallet.lockedBalance = centsToMoney(locked + amount);
      const withdrawal = await manager.getRepository(WithdrawalRequest).save(
        manager.getRepository(WithdrawalRequest).create({
          providerId: provider.id,
          amount: centsToMoney(amount),
          status: WithdrawalStatus.PENDING,
          processedById: null,
          processedAt: null,
          decisionReason: null,
        }),
      );
      await manager.getRepository(Wallet).save(wallet);
      return this.response(withdrawal, wallet);
    });
  }

  async mine(providerUserId: number) {
    const provider = await this.database.getRepository(Provider).findOneBy({ userId: providerUserId });
    if (!provider) throw new NotFoundException('Provider profile not found');
    const [wallet, withdrawals] = await Promise.all([
      this.database.getRepository(Wallet).findOneBy({ providerId: provider.id }),
      this.database.getRepository(WithdrawalRequest).find({
        where: { providerId: provider.id },
        order: { createdAt: 'DESC', id: 'DESC' },
        take: 50,
      }),
    ]);
    return {
      providerId: provider.id,
      wallet: this.walletSummary(wallet),
      sandboxOnly: true,
      items: withdrawals.map((withdrawal) => this.format(withdrawal)),
    };
  }

  async pending() {
    const withdrawals = await this.database.getRepository(WithdrawalRequest).find({
      where: { status: WithdrawalStatus.PENDING },
      relations: { provider: { user: true } },
      order: { createdAt: 'ASC', id: 'ASC' },
      take: 50,
    });
    return withdrawals.map((withdrawal) => ({
      ...this.format(withdrawal),
      provider: {
        id: withdrawal.provider.id,
        userId: withdrawal.provider.userId,
        name: withdrawal.provider.user.name,
      },
    }));
  }

  async resolve(requestId: number, adminId: number, decision: WithdrawalDecision, reason?: string) {
    return this.database.transaction(async (manager) => {
      const withdrawal = await manager.getRepository(WithdrawalRequest).findOne({
        where: { id: requestId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!withdrawal) throw new NotFoundException('Withdrawal request not found');
      const targetStatus = decision === WithdrawalDecision.APPROVE
        ? WithdrawalStatus.APPROVED
        : WithdrawalStatus.REJECTED;
      if (withdrawal.status !== WithdrawalStatus.PENDING) {
        if (withdrawal.status === targetStatus) {
          const currentWallet = await manager.getRepository(Wallet).findOneByOrFail({ providerId: withdrawal.providerId });
          return this.response(withdrawal, currentWallet);
        }
        throw new ConflictException('Withdrawal request was already resolved differently');
      }
      if (decision === WithdrawalDecision.REJECT && !reason?.trim()) {
        throw new ConflictException('A rejection reason is required');
      }
      const wallet = await this.lockWallet(manager, withdrawal.providerId);
      const amount = moneyToCents(withdrawal.amount);
      const balance = moneyToCents(wallet.balance);
      const locked = moneyToCents(wallet.lockedBalance);
      if (locked < amount || balance < amount) {
        throw new ConflictException('Wallet reservation no longer reconciles with this request');
      }
      wallet.lockedBalance = centsToMoney(locked - amount);
      if (decision === WithdrawalDecision.APPROVE) {
        wallet.balance = centsToMoney(balance - amount);
        await manager.getRepository(WalletTransaction).save(
          manager.getRepository(WalletTransaction).create({
            walletId: wallet.id,
            type: WalletTransactionType.DEBIT,
            amount: withdrawal.amount,
            orderId: null,
            withdrawalId: withdrawal.id,
          }),
        );
      }
      withdrawal.status = targetStatus;
      withdrawal.processedById = adminId;
      withdrawal.processedAt = new Date();
      withdrawal.decisionReason = reason?.trim() || null;
      await manager.getRepository(Wallet).save(wallet);
      await manager.getRepository(WithdrawalRequest).save(withdrawal);
      return this.response(withdrawal, wallet);
    });
  }

  private async lockProvider(manager: EntityManager, userId: number): Promise<Provider> {
    const provider = await manager.getRepository(Provider).findOne({
      where: { userId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!provider) throw new NotFoundException('Provider profile not found');
    return provider;
  }

  private async lockWallet(manager: EntityManager, providerId: number): Promise<Wallet> {
    const wallet = await manager.getRepository(Wallet).findOne({
      where: { providerId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!wallet) throw new ConflictException('Provider has no demo wallet balance');
    return wallet;
  }

  private response(withdrawal: WithdrawalRequest, wallet: Wallet) {
    return {
      withdrawal: this.format(withdrawal),
      wallet: this.walletSummary(wallet),
      sandboxOnly: true,
    };
  }

  private walletSummary(wallet: Wallet | null) {
    const balance = moneyToCents(wallet?.balance ?? '0.00');
    const locked = moneyToCents(wallet?.lockedBalance ?? '0.00');
    return {
      balance: centsToMoney(balance),
      lockedBalance: centsToMoney(locked),
      availableBalance: centsToMoney(balance - locked),
      currency: 'VND',
    };
  }

  private format(withdrawal: WithdrawalRequest) {
    return {
      id: withdrawal.id,
      providerId: withdrawal.providerId,
      amount: withdrawal.amount,
      status: withdrawal.status,
      decisionReason: withdrawal.decisionReason,
      processedById: withdrawal.processedById,
      processedAt: withdrawal.processedAt,
      createdAt: withdrawal.createdAt,
      updatedAt: withdrawal.updatedAt,
    };
  }
}
