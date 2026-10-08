import { ConflictException, ForbiddenException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PaymentStatus } from '../common/enums/payment-status.enum';
import { MatchingService } from '../orders/matching.service';
import { Order } from '../orders/order.entity';
import { Payment } from './payment.entity';
import { RealtimePublisher } from '../realtime/realtime-publisher.port';
import { PaymentAdjustmentStatus, PaymentAdjustmentType } from '../common/enums/payment-adjustment.enum';
import { PaymentAdjustment } from './payment-adjustment.entity';
import { canTransitionOrder } from '../orders/domain/order-transition.policy';

@Injectable()
export class DemoPaymentsService {
  constructor(
    private readonly database: DataSource,
    private readonly config: ConfigService,
    private readonly matching: MatchingService,
    @Optional() private readonly realtime?: RealtimePublisher,
  ) {}

  private assertEnabled(): void {
    if (this.config.get<string>('NODE_ENV') === 'production' || !this.config.get<boolean>('DEMO_MODE')) {
      throw new ForbiddenException('Demo payments are disabled');
    }
  }

  async confirm(orderId: number, customerId: number) {
    this.assertEnabled();
    const result = await this.database.transaction(async (manager) => {
      const order = await manager.getRepository(Order).findOne({
        where: { id: orderId }, lock: { mode: 'pessimistic_write' },
      });
      if (!order || order.customerId !== customerId) throw new NotFoundException('Order not found');
      const payment = await manager.getRepository(Payment).findOne({
        where: { orderId }, lock: { mode: 'pessimistic_write' }, order: { id: 'ASC' },
      });
      if (!payment) throw new NotFoundException('Prepayment not found');
      if (payment.isDemo && payment.status === PaymentStatus.PAID) {
        return { orderId, status: order.status, paymentStatus: payment.status, matched: order.status === OrderStatus.OFFERED, offer: null, changed: false };
      }
      if (!canTransitionOrder(order.status, OrderStatus.PENDING_MATCH) || payment.status !== PaymentStatus.PENDING) {
        throw new ConflictException('Order is not awaiting a demo payment');
      }
      if (payment.amount !== order.estimatedPrice) {
        throw new ConflictException('Prepayment amount does not match the estimated price');
      }
      payment.isDemo = true;
      payment.status = PaymentStatus.PAID;
      payment.paidAt = new Date();
      await manager.getRepository(Payment).save(payment);
      order.status = OrderStatus.PENDING_MATCH;
      await manager.getRepository(Order).save(order);
      const offer = await this.matching.matchLockedOrder(manager, order);
      return { orderId, status: order.status, paymentStatus: payment.status, matched: offer !== null, offer, changed: true };
    });
    if (result.changed) this.realtime?.orderStatusChanged(orderId, result.status);
    if (result.offer) {
      this.realtime?.offerCreated(result.offer.providerId, orderId, result.offer.id, result.offer.expiresAt);
    }
    return { orderId: result.orderId, status: result.status, paymentStatus: result.paymentStatus, matched: result.matched };
  }

  async refund(orderId: number) {
    this.assertEnabled();
    const result = await this.database.transaction(async (manager) => {
      const order = await manager.getRepository(Order).findOne({
        where: { id: orderId }, lock: { mode: 'pessimistic_write' },
      });
      if (!order) throw new NotFoundException('Order not found');
      const payment = await manager.getRepository(Payment).findOne({
        where: { orderId }, lock: { mode: 'pessimistic_write' }, order: { id: 'ASC' },
      });
      if (!payment?.isDemo) throw new ConflictException('Only demo payments can be refunded here');
      if (payment.status === PaymentStatus.REFUNDED && order.status === OrderStatus.REFUNDED) {
        return { orderId, status: order.status, paymentStatus: payment.status, amount: payment.amount };
      }
      if (!canTransitionOrder(order.status, OrderStatus.REFUNDED) || payment.status !== PaymentStatus.REFUND_PENDING) {
        throw new ConflictException('Order is not awaiting a demo refund');
      }
      payment.status = PaymentStatus.REFUNDED;
      payment.refundedAt = new Date();
      order.status = OrderStatus.REFUNDED;
      await manager.getRepository(Payment).save(payment);
      await manager.getRepository(Order).save(order);
      return { orderId, status: order.status, paymentStatus: payment.status, amount: payment.amount };
    });
    this.realtime?.orderStatusChanged(orderId, result.status);
    return result;
  }

  async confirmAdjustment(orderId: number, customerId: number) {
    return this.settleAdjustment(orderId, PaymentAdjustmentType.CHARGE, customerId);
  }

  async refundAdjustment(orderId: number) {
    return this.settleAdjustment(orderId, PaymentAdjustmentType.REFUND);
  }

  private async settleAdjustment(orderId: number, type: PaymentAdjustmentType, customerId?: number) {
    this.assertEnabled();
    const result = await this.database.transaction(async (manager) => {
      const order = await manager.getRepository(Order).findOne({
        where: { id: orderId }, lock: { mode: 'pessimistic_write' },
      });
      if (!order || (customerId !== undefined && order.customerId !== customerId)) {
        throw new NotFoundException('Order not found');
      }
      const adjustment = await manager.getRepository(PaymentAdjustment).findOne({
        where: { orderId }, lock: { mode: 'pessimistic_write' },
      });
      if (!adjustment || adjustment.type !== type) {
        throw new ConflictException(`Order has no pending ${type.toLowerCase()} adjustment`);
      }
      if (adjustment.status === PaymentAdjustmentStatus.SETTLED && order.status === OrderStatus.PAID) {
        return { orderId, status: order.status, adjustment, changed: false };
      }
      if (order.status !== OrderStatus.AWAITING_PAYMENT
        || !canTransitionOrder(order.status, OrderStatus.PAID)
        || adjustment.status !== PaymentAdjustmentStatus.PENDING) {
        throw new ConflictException('Payment adjustment is no longer pending');
      }
      const payment = await manager.getRepository(Payment).findOne({
        where: { id: adjustment.paymentId }, lock: { mode: 'pessimistic_write' },
      });
      if (!payment?.isDemo || payment.status !== PaymentStatus.PAID) {
        throw new ConflictException('Only a paid demo prepayment can be adjusted here');
      }
      adjustment.status = PaymentAdjustmentStatus.SETTLED;
      adjustment.isDemo = true;
      adjustment.settledAt = new Date();
      order.status = OrderStatus.PAID;
      await manager.getRepository(PaymentAdjustment).save(adjustment);
      await manager.getRepository(Order).save(order);
      return { orderId, status: order.status, adjustment, changed: true };
    });
    if (result.changed) this.realtime?.orderStatusChanged(orderId, result.status);
    return {
      orderId,
      status: result.status,
      paymentAdjustment: {
        id: result.adjustment.id,
        type: result.adjustment.type,
        amount: result.adjustment.amount,
        status: result.adjustment.status,
        isDemo: result.adjustment.isDemo,
        settledAt: result.adjustment.settledAt,
      },
    };
  }
}
