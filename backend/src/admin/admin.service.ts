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
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class AdminService {
  constructor(
    private readonly database: DataSource,
    private readonly notifications: NotificationsService,
  ) {}

  async recentOrders() {
    const orders = await this.database.getRepository(Order).find({ order: { createdAt: 'DESC', id: 'DESC' }, take: 50 });
    return orders.map((order) => ({
      id: order.id, code: order.code, status: order.status, customerId: order.customerId,
      providerId: order.providerId, estimatedPrice: order.estimatedPrice, finalPrice: order.finalPrice,
      createdAt: order.createdAt,
    }));
  }

  async orderDetail(orderId: number) {
    const order = await this.database.getRepository(Order).findOne({
      where: { id: orderId }, relations: { incidentType: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    const customer = await this.database.getRepository(User).findOneBy({ id: order.customerId });
    let provider: { id: number; name: string; phone: string | null; currentLocation: unknown } | null = null;
    if (order.providerId) {
      const row = await this.database.getRepository(Provider).findOne({
        where: { id: order.providerId }, relations: { user: true },
      });
      if (row) {
        provider = {
          id: row.id, name: row.user?.name ?? 'Thợ', phone: row.user?.phone ?? null,
          currentLocation: row.currentLocation ?? null,
        };
      }
    }
    return {
      id: order.id, code: order.code, status: order.status, createdAt: order.createdAt,
      incidentType: order.incidentType?.name ?? null,
      estimatedPrice: order.estimatedPrice, extraCost: order.extraCost,
      discountAmount: order.discountAmount, finalPrice: order.finalPrice,
      customerLocation: order.customerLocation,
      customer: customer
        ? { id: customer.id, name: customer.name, phone: customer.phone, address: customer.homeAddress }
        : null,
      provider,
    };
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
    const result = await this.database.transaction(async (manager) => {
      const provider = await manager.getRepository(Provider).findOne({
        where: { id: providerId }, lock: { mode: 'pessimistic_write' },
      });
      if (!provider) throw new NotFoundException('Provider not found');
      if (provider.approvalStatus !== ApprovalStatus.PENDING) throw new ConflictException('Provider was already reviewed');
      const user = await manager.getRepository(User).findOneBy({ id: provider.userId });
      // Two valid pending shapes: a provider sign-up (already role PROVIDER,
      // status PENDING_APPROVAL) and an existing customer applying to become a
      // provider (still role CUSTOMER, status ACTIVE).
      const isProviderSignup =
        user?.role === UserRole.PROVIDER &&
        user.status === UserStatus.PENDING_APPROVAL;
      const isCustomerApplication =
        user?.role === UserRole.CUSTOMER && user.status === UserStatus.ACTIVE;
      if (!user || (!isProviderSignup && !isCustomerApplication)) {
        throw new ConflictException('Provider account is not awaiting approval');
      }
      provider.approvalStatus = status;
      provider.isOnline = false;
      if (status === ApprovalStatus.APPROVED) {
        // Promote: a customer becomes a provider (which invalidates their
        // current customer session via authVersion); a sign-up is activated.
        user.role = UserRole.PROVIDER;
        user.status = UserStatus.ACTIVE;
        if (isCustomerApplication) user.authVersion += 1;
      } else if (isProviderSignup) {
        // A rejected provider sign-up is suspended, as before.
        user.status = UserStatus.SUSPENDED;
      }
      // A rejected customer application leaves the customer account untouched.
      await manager.getRepository(Provider).save(provider);
      await manager.getRepository(User).save(user);
      return {
        id: provider.id,
        userId: provider.userId,
        approvalStatus: provider.approvalStatus,
        accountStatus: user.status,
        role: user.role,
      };
    });
    // Tell the applicant the outcome. Best-effort: a failed notification must
    // not roll back a completed review decision.
    try {
      await this.notifications.notifyProviderReviewed(
        result.userId,
        status === ApprovalStatus.APPROVED,
      );
    } catch {
      // Swallow: the review stands regardless of notification delivery.
    }
    return result;
  }
}
