import { ConflictException, ForbiddenException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PaymentStatus } from '../common/enums/payment-status.enum';
import { MatchingService } from '../orders/matching.service';
import { Order } from '../orders/order.entity';
import { Payment } from './payment.entity';
import { RealtimeGateway } from '../realtime/realtime.gateway';

@Injectable()
export class DemoPaymentsService {
  constructor(
    private readonly database: DataSource,
    private readonly config: ConfigService,
    private readonly matching: MatchingService,
    @Optional() private readonly realtime?: RealtimeGateway,
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
      if (order.status !== OrderStatus.AWAITING_PREPAYMENT || payment.status !== PaymentStatus.PENDING) {
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
      if (order.status !== OrderStatus.REFUND_PENDING || payment.status !== PaymentStatus.REFUND_PENDING) {
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
}
