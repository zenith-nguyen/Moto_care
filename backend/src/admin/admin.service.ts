import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, In } from 'typeorm';
import { ApprovalStatus } from '../common/enums/approval-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { Payment } from '../payments/payment.entity';
import { Provider } from '../providers/provider.entity';
import { User } from '../users/user.entity';

@Injectable()
export class AdminService {
  constructor(private readonly database: DataSource) {}

  async recentOrders() {
    const orders = await this.database.getRepository(Order).find({ order: { createdAt: 'DESC', id: 'DESC' }, take: 50 });
    return orders.map((order) => ({
      id: order.id, code: order.code, status: order.status, customerId: order.customerId,
      providerId: order.providerId, estimatedPrice: order.estimatedPrice, finalPrice: order.finalPrice,
      createdAt: order.createdAt,
    }));
  }

  async pendingRefunds() {
    const orders = await this.database.getRepository(Order).find({
      where: { status: In([OrderStatus.REFUND_PENDING]) }, order: { createdAt: 'ASC', id: 'ASC' }, take: 50,
    });
    const payments = orders.length ? await this.database.getRepository(Payment).find({
      where: { orderId: In(orders.map((order) => order.id)) },
    }) : [];
    const byOrder = new Map(payments.map((payment) => [payment.orderId, payment]));
    return orders.map((order) => ({
      orderId: order.id, code: order.code, customerId: order.customerId,
      amount: byOrder.get(order.id)?.amount ?? null, isDemo: byOrder.get(order.id)?.isDemo ?? false,
      reason: order.cancelReason, createdAt: order.createdAt,
    }));
  }

  async pendingProviders() {
    const providers = await this.database.getRepository(Provider).find({
      where: { approvalStatus: ApprovalStatus.PENDING }, relations: { user: true }, order: { id: 'ASC' },
    });
    return providers.map((provider) => ({
      id: provider.id, userId: provider.userId, name: provider.user.name,
      email: provider.user.email, phone: provider.user.phone,
      approvalStatus: provider.approvalStatus, documentUrl: provider.documentUrl,
    }));
  }

  async reviewProvider(providerId: number, status: ApprovalStatus) {
    if (![ApprovalStatus.APPROVED, ApprovalStatus.REJECTED].includes(status)) {
      throw new ConflictException('Review must approve or reject');
    }
    return this.database.transaction(async (manager) => {
      const provider = await manager.getRepository(Provider).findOne({
        where: { id: providerId }, lock: { mode: 'pessimistic_write' },
      });
      if (!provider) throw new NotFoundException('Provider not found');
      if (provider.approvalStatus !== ApprovalStatus.PENDING) throw new ConflictException('Provider was already reviewed');
      const user = await manager.getRepository(User).findOneBy({ id: provider.userId });
      if (!user || user.role !== UserRole.PROVIDER || user.status !== UserStatus.PENDING_APPROVAL) {
        throw new ConflictException('Provider account is not awaiting approval');
      }
      provider.approvalStatus = status;
      provider.isOnline = false;
      user.status = status === ApprovalStatus.APPROVED ? UserStatus.ACTIVE : UserStatus.SUSPENDED;
      await manager.getRepository(Provider).save(provider);
      await manager.getRepository(User).save(user);
      return { id: provider.id, userId: provider.userId, approvalStatus: provider.approvalStatus, accountStatus: user.status };
    });
  }
}
