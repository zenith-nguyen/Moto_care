import { ConflictException, Injectable } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { PaymentAdjustmentStatus, PaymentAdjustmentType } from '../../common/enums/payment-adjustment.enum';
import { PaymentStatus } from '../../common/enums/payment-status.enum';
import { WalletTransactionType } from '../../common/enums/wallet-transaction-type.enum';
import { centsToMoney, moneyToCents } from '../../common/utils/money';
import {
  PaymentAdjustmentSnapshot,
  PaymentQueryPort,
  PaymentSnapshot,
  PendingRefundAdjustmentSnapshot,
} from '../application/payment-query.port';
import {
  FinalPricePaymentPlan,
  PaymentSettlementPort,
  PreServiceCancellationResult,
} from '../application/payment-settlement.port';
import { PaymentAdjustment } from '../payment-adjustment.entity';
import { Payment } from '../payment.entity';
import { WalletTransaction } from '../wallet-transaction.entity';
import { Wallet } from '../wallet.entity';

@Injectable()
export class TypeOrmPaymentAccountingAdapter implements PaymentSettlementPort, PaymentQueryPort {
  constructor(private readonly database: DataSource) {}

  async createPrepayment(
    manager: EntityManager,
    command: { orderId: number; amount: string },
  ): Promise<void> {
    await manager.getRepository(Payment).save(
      manager.getRepository(Payment).create({
        orderId: command.orderId,
        amount: command.amount,
        status: PaymentStatus.PENDING,
        isDemo: false,
      }),
    );
  }

  async cancelBeforeService(
    manager: EntityManager,
    orderId: number,
  ): Promise<PreServiceCancellationResult> {
    const payment = await manager.getRepository(Payment).findOne({
      where: { orderId },
      lock: { mode: 'pessimistic_write' },
      order: { id: 'ASC' },
    });
    if (!payment) return { requiresRefund: false, refundAmount: null };

    if (payment.status === PaymentStatus.PAID) {
      payment.status = PaymentStatus.REFUND_PENDING;
      await manager.getRepository(Payment).save(payment);
      return { requiresRefund: true, refundAmount: payment.amount };
    }

    payment.status = PaymentStatus.CANCELLED;
    await manager.getRepository(Payment).save(payment);
    return { requiresRefund: false, refundAmount: null };
  }

  async prepareFinalPrice(
    manager: EntityManager,
    command: { orderId: number; finalPrice: string },
  ): Promise<FinalPricePaymentPlan> {
    const payment = await manager.getRepository(Payment).findOne({
      where: { orderId: command.orderId },
      lock: { mode: 'pessimistic_write' },
      order: { id: 'ASC' },
    });
    if (!payment || payment.status !== PaymentStatus.PAID) {
      throw new ConflictException('Prepayment must be paid before final-price approval');
    }

    const prepaid = moneyToCents(payment.amount);
    const finalPrice = moneyToCents(command.finalPrice);
    const extraCost = finalPrice > prepaid ? finalPrice - prepaid : 0n;
    const discountAmount = finalPrice < prepaid ? prepaid - finalPrice : 0n;
    const requiresAdjustment = finalPrice !== prepaid;

    if (requiresAdjustment) {
      await manager.getRepository(PaymentAdjustment).save(
        manager.getRepository(PaymentAdjustment).create({
          orderId: command.orderId,
          paymentId: payment.id,
          type: finalPrice > prepaid ? PaymentAdjustmentType.CHARGE : PaymentAdjustmentType.REFUND,
          amount: centsToMoney(finalPrice > prepaid ? extraCost : discountAmount),
          status: PaymentAdjustmentStatus.PENDING,
          isDemo: false,
        }),
      );
    }

    return {
      finalPrice: centsToMoney(finalPrice),
      extraCost: centsToMoney(extraCost),
      discountAmount: centsToMoney(discountAmount),
      requiresAdjustment,
    };
  }

  async settleProviderEarnings(
    manager: EntityManager,
    command: { orderId: number; providerId: number; estimatedPrice: string; finalPrice: string },
  ): Promise<void> {
    const payment = await manager.getRepository(Payment).findOne({
      where: { orderId: command.orderId },
      lock: { mode: 'pessimistic_write' },
      order: { id: 'ASC' },
    });
    if (!payment?.isDemo || payment.status !== PaymentStatus.PAID || payment.amount !== command.estimatedPrice) {
      throw new ConflictException('Only a paid demo order can be completed');
    }

    const adjustment = await manager.getRepository(PaymentAdjustment).findOne({
      where: { orderId: command.orderId },
      lock: { mode: 'pessimistic_write' },
    });
    const prepaid = moneyToCents(payment.amount);
    const expectedFinal = adjustment
      ? adjustment.type === PaymentAdjustmentType.CHARGE
        ? prepaid + moneyToCents(adjustment.amount)
        : prepaid - moneyToCents(adjustment.amount)
      : prepaid;
    if (expectedFinal < 0n || moneyToCents(command.finalPrice) !== expectedFinal) {
      throw new ConflictException('Final price does not reconcile with payment records');
    }
    if (adjustment && (!adjustment.isDemo || adjustment.status !== PaymentAdjustmentStatus.SETTLED)) {
      throw new ConflictException('Payment adjustment is not settled');
    }

    await manager.query(
      'INSERT INTO wallets (provider_id, balance) VALUES ($1, 0) ON CONFLICT (provider_id) DO NOTHING',
      [command.providerId],
    );
    const wallet = await manager.getRepository(Wallet).findOne({
      where: { providerId: command.providerId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!wallet) throw new ConflictException('Provider wallet unavailable');

    await manager.query(
      'UPDATE wallets SET balance = balance + $1::numeric WHERE id = $2',
      [command.finalPrice, wallet.id],
    );
    await manager.getRepository(WalletTransaction).save(
      manager.getRepository(WalletTransaction).create({
        walletId: wallet.id,
        type: WalletTransactionType.CREDIT,
        amount: command.finalPrice,
        orderId: command.orderId,
      }),
    );
  }

  async getOrderFinancials(orderId: number): Promise<{
    payment: PaymentSnapshot | null;
    adjustment: PaymentAdjustmentSnapshot | null;
  }> {
    const [payment, adjustment] = await Promise.all([
      this.database.getRepository(Payment).findOne({ where: { orderId }, order: { id: 'ASC' } }),
      this.database.getRepository(PaymentAdjustment).findOneBy({ orderId }),
    ]);
    return {
      payment: payment ? this.paymentSnapshot(payment) : null,
      adjustment: adjustment ? this.adjustmentSnapshot(adjustment) : null,
    };
  }

  async getAdjustment(manager: EntityManager, orderId: number): Promise<PaymentAdjustmentSnapshot | null> {
    const adjustment = await manager.getRepository(PaymentAdjustment).findOneBy({ orderId });
    return adjustment ? this.adjustmentSnapshot(adjustment) : null;
  }

  async listPendingRefundAdjustments(limit: number): Promise<PendingRefundAdjustmentSnapshot[]> {
    const adjustments = await this.database.getRepository(PaymentAdjustment).find({
      where: { type: PaymentAdjustmentType.REFUND, status: PaymentAdjustmentStatus.PENDING },
      relations: { order: true },
      order: { createdAt: 'ASC', id: 'ASC' },
      take: limit,
    });
    return adjustments.map((adjustment) => ({
      ...this.adjustmentSnapshot(adjustment),
      order: {
        id: adjustment.order.id,
        code: adjustment.order.code,
        customerId: adjustment.order.customerId,
        providerId: adjustment.order.providerId,
        estimatedPrice: adjustment.order.estimatedPrice,
        finalPrice: adjustment.order.finalPrice,
      },
    }));
  }

  private paymentSnapshot(payment: Payment): PaymentSnapshot {
    return {
      id: payment.id,
      amount: payment.amount,
      status: payment.status,
      isDemo: payment.isDemo,
    };
  }

  private adjustmentSnapshot(adjustment: PaymentAdjustment): PaymentAdjustmentSnapshot {
    return {
      id: adjustment.id,
      type: adjustment.type,
      amount: adjustment.amount,
      status: adjustment.status,
      isDemo: adjustment.isDemo,
      settledAt: adjustment.settledAt,
    };
  }
}
