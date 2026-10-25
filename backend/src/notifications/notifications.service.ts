import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource, EntityManager, IsNull, LessThan } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { Provider } from '../providers/provider.entity';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { ListNotificationsDto } from './dto/list-notifications.dto';
import { NotificationDeliveryStatus } from './notification-delivery-status.enum';
import { NotificationDelivery } from './notification-delivery.entity';
import { Notification, NotificationData } from './notification.entity';
import { NotificationType } from './notification-type.enum';
import { PushGateway } from './push-gateway.port';
import { UserDevice } from './user-device.entity';

export interface CreateNotificationInput {
  userId: number;
  type: NotificationType;
  title: string;
  body: string;
  data?: NotificationData;
  dedupeKey?: string;
  expiresAt?: Date;
}

@Injectable()
export class NotificationsService {
  constructor(
    private readonly database: DataSource,
    private readonly push: PushGateway,
    private readonly config: ConfigService,
  ) {}

  async registerDevice(userId: number, dto: RegisterDeviceDto) {
    const now = new Date();
    const device = await this.database.transaction(async (manager) => {
      await manager.createQueryBuilder()
        .delete()
        .from(UserDevice)
        .where('fcm_token = :token AND installation_id <> :installationId', {
          token: dto.fcmToken,
          installationId: dto.installationId,
        })
        .execute();
      const repository = manager.getRepository(UserDevice);
      const existing = await repository.findOneBy({ installationId: dto.installationId });
      if (existing) {
        await repository.update(existing.id, {
          userId,
          fcmToken: dto.fcmToken,
          platform: dto.platform,
          isEnabled: true,
          lastSeenAt: now,
        });
        return repository.findOneByOrFail({ id: existing.id });
      }
      return repository.save(repository.create({
        userId,
        installationId: dto.installationId,
        fcmToken: dto.fcmToken,
        platform: dto.platform,
        isEnabled: true,
        lastSeenAt: now,
      }));
    });
    return this.presentDevice(device);
  }

  async unregisterDevice(userId: number, installationId: string) {
    const result = await this.database.getRepository(UserDevice).update(
      { userId, installationId },
      { isEnabled: false, lastSeenAt: new Date() },
    );
    if (!result.affected) throw new NotFoundException('Device registration not found');
    return { installationId, isEnabled: false };
  }

  async list(userId: number, query: ListNotificationsDto) {
    const repository = this.database.getRepository(Notification);
    const where = {
      userId,
      ...(query.cursor ? { id: LessThan(query.cursor) } : {}),
      ...(query.unreadOnly ? { readAt: IsNull() } : {}),
    };
    const [items, unreadCount] = await Promise.all([
      repository.find({ where, order: { id: 'DESC' }, take: query.limit + 1 }),
      repository.countBy({ userId, readAt: IsNull() }),
    ]);
    const hasMore = items.length > query.limit;
    const page = hasMore ? items.slice(0, query.limit) : items;
    return {
      items: page.map((item) => this.presentNotification(item)),
      nextCursor: hasMore ? page.at(-1)?.id ?? null : null,
      unreadCount,
    };
  }

  async markRead(userId: number, notificationId: number) {
    const repository = this.database.getRepository(Notification);
    const notification = await repository.findOneBy({ id: notificationId, userId });
    if (!notification) throw new NotFoundException('Notification not found');
    if (!notification.readAt) {
      notification.readAt = new Date();
      await repository.save(notification);
    }
    return this.presentNotification(notification);
  }

  async markAllRead(userId: number) {
    const readAt = new Date();
    const result = await this.database.getRepository(Notification).update(
      { userId, readAt: IsNull() },
      { readAt },
    );
    return { updatedCount: result.affected ?? 0, readAt };
  }

  async create(input: CreateNotificationInput): Promise<Notification> {
    return this.database.transaction((manager) => this.createWithManager(manager, input));
  }

  async notifyOfferCreated(providerId: number, orderId: number, offerId: number, expiresAt: Date): Promise<void> {
    const provider = await this.database.getRepository(Provider).findOneBy({ id: providerId });
    if (!provider) return;
    await this.create({
      userId: provider.userId,
      type: NotificationType.OFFER_CREATED,
      title: 'Có yêu cầu cứu hộ mới',
      body: 'Bạn có 15 giây để xem và phản hồi yêu cầu.',
      data: { route: 'provider_offer', orderId: String(orderId), offerId: String(offerId) },
      dedupeKey: `offer:${offerId}:created`,
      expiresAt,
    });
  }

  async notifyOfferExpired(providerId: number, orderId: number, offerId: number): Promise<void> {
    const provider = await this.database.getRepository(Provider).findOneBy({ id: providerId });
    if (!provider) return;
    await this.create({
      userId: provider.userId,
      type: NotificationType.OFFER_EXPIRED,
      title: 'Yêu cầu đã hết hạn',
      body: 'Yêu cầu cứu hộ đã được chuyển sang thợ khác.',
      data: { route: 'provider_offers', orderId: String(orderId), offerId: String(offerId) },
      dedupeKey: `offer:${offerId}:expired`,
    });
  }

  async notifyOrderStatusChanged(orderId: number, status: OrderStatus): Promise<void> {
    const order = await this.database.getRepository(Order).findOneBy({ id: orderId });
    if (!order) return;
    const recipients = new Set<number>([order.customerId]);
    if (order.providerId) {
      const provider = await this.database.getRepository(Provider).findOneBy({ id: order.providerId });
      if (provider) recipients.add(provider.userId);
    }
    await Promise.all([...recipients].map((userId) => this.create({
      userId,
      type: NotificationType.ORDER_STATUS_CHANGED,
      title: 'Đơn cứu hộ đã cập nhật',
      body: this.statusBody(status),
      data: { route: 'order_detail', orderId: String(orderId), status },
    })));
  }

  async notifyMessageCreated(orderId: number, senderId: number, messageId: number): Promise<void> {
    const order = await this.database.getRepository(Order).findOneBy({ id: orderId });
    if (!order) return;
    let recipientId = order.customerId;
    if (senderId === order.customerId) {
      if (!order.providerId) return;
      const provider = await this.database.getRepository(Provider).findOneBy({ id: order.providerId });
      if (!provider) return;
      recipientId = provider.userId;
    }
    if (recipientId === senderId) return;
    await this.create({
      userId: recipientId,
      type: NotificationType.MESSAGE_CREATED,
      title: 'Tin nhắn mới',
      body: 'Bạn có tin nhắn mới trong đơn cứu hộ.',
      data: { route: 'order_chat', orderId: String(orderId), messageId: String(messageId) },
      dedupeKey: `message:${messageId}:created`,
    });
  }

  async notifyProviderReviewed(userId: number, approved: boolean): Promise<void> {
    await this.create({
      userId,
      type: NotificationType.SYSTEM,
      title: approved ? 'Hồ sơ thợ đã được duyệt' : 'Hồ sơ thợ chưa được duyệt',
      body: approved
        ? 'Chúc mừng! Hồ sơ thợ của bạn đã được duyệt. Vui lòng đăng nhập lại để bắt đầu nhận đơn.'
        : 'Rất tiếc, hồ sơ thợ của bạn chưa được duyệt lần này. Vui lòng liên hệ hỗ trợ để biết thêm chi tiết.',
      data: { route: approved ? 'provider_home' : 'support' },
      dedupeKey: `provider:${userId}:review:${approved ? 'approved' : 'rejected'}`,
    });
  }

  async notifyProviderNearby(orderId: number): Promise<void> {
    const order = await this.database.getRepository(Order).findOneBy({ id: orderId });
    if (!order) return;
    await this.create({
      userId: order.customerId,
      type: NotificationType.PROVIDER_NEARBY,
      title: 'Thợ sắp đến',
      body: 'Thợ cứu hộ đang ở gần vị trí của bạn.',
      data: { route: 'order_tracking', orderId: String(orderId) },
      dedupeKey: `order:${orderId}:provider-nearby`,
    });
  }

  async notifyProviderNearbyIfWithin(orderId: number, providerId: number): Promise<void> {
    const dedupeKey = `order:${orderId}:provider-nearby`;
    const existing = await this.database.getRepository(Notification).findOneBy({ dedupeKey });
    if (existing) return;
    const radiusMeters = this.config.getOrThrow<number>('PROVIDER_NEARBY_RADIUS_METERS');
    const rows = (await this.database.query(`
      SELECT ST_Distance(order_row.customer_location, provider.current_location) AS distance_meters
      FROM orders order_row
      INNER JOIN providers provider ON provider.id = order_row.provider_id
      WHERE order_row.id = $1
        AND provider.id = $2
        AND order_row.status = 'ACCEPTED'
        AND provider.current_location IS NOT NULL
    `, [orderId, providerId])) as Array<{ distance_meters: string }>;
    if (rows.length === 0 || Number(rows[0].distance_meters) > radiusMeters) return;
    await this.notifyProviderNearby(orderId);
  }

  private async createWithManager(manager: EntityManager, input: CreateNotificationInput): Promise<Notification> {
    const repository = manager.getRepository(Notification);
    if (input.dedupeKey) {
      const existing = await repository.findOneBy({ dedupeKey: input.dedupeKey });
      if (existing) return existing;
    }
    let notification: Notification;
    try {
      notification = await repository.save(repository.create({
        userId: input.userId,
        type: input.type,
        title: input.title,
        body: input.body,
        data: input.data ?? {},
        dedupeKey: input.dedupeKey ?? null,
        readAt: null,
        expiresAt: input.expiresAt ?? null,
      }));
    } catch (error) {
      if (input.dedupeKey && this.postgresCode(error) === '23505') {
        return repository.findOneByOrFail({ dedupeKey: input.dedupeKey });
      }
      throw error;
    }
    if (this.push.enabled) {
      const devices = await manager.getRepository(UserDevice).findBy({ userId: input.userId, isEnabled: true });
      if (devices.length > 0) {
        await manager.getRepository(NotificationDelivery).save(devices.map((device) =>
          manager.getRepository(NotificationDelivery).create({
            notificationId: notification.id,
            deviceId: device.id,
            status: NotificationDeliveryStatus.PENDING,
            attemptCount: 0,
            nextAttemptAt: new Date(),
            sentAt: null,
            lastErrorCode: null,
          }),
        ));
      }
    }
    return notification;
  }

  private statusBody(status: OrderStatus): string {
    const labels: Partial<Record<OrderStatus, string>> = {
      [OrderStatus.PENDING_MATCH]: 'Hệ thống đang tìm thợ phù hợp.',
      [OrderStatus.OFFERED]: 'Đã gửi yêu cầu đến thợ gần nhất.',
      [OrderStatus.ACCEPTED]: 'Thợ đã nhận đơn và đang di chuyển.',
      [OrderStatus.ARRIVED]: 'Thợ đã đến vị trí của bạn.',
      [OrderStatus.IN_PROGRESS]: 'Dịch vụ cứu hộ đã bắt đầu.',
      [OrderStatus.AWAITING_PRICE_APPROVAL]: 'Có đề xuất giá cuối cần xác nhận.',
      [OrderStatus.AWAITING_PAYMENT]: 'Đơn đang chờ hoàn tất thanh toán.',
      [OrderStatus.PAID]: 'Thanh toán đã được xác nhận.',
      [OrderStatus.COMPLETED]: 'Đơn cứu hộ đã hoàn thành.',
      [OrderStatus.CANCELLED]: 'Đơn cứu hộ đã bị hủy.',
      [OrderStatus.REFUND_PENDING]: 'Khoản hoàn tiền đang chờ xử lý.',
      [OrderStatus.REFUNDED]: 'Khoản tiền đã được hoàn.',
    };
    return labels[status] ?? `Trạng thái mới: ${status}`;
  }

  private presentDevice(device: UserDevice) {
    return {
      id: device.id,
      installationId: device.installationId,
      platform: device.platform,
      isEnabled: device.isEnabled,
      lastSeenAt: device.lastSeenAt,
    };
  }

  private presentNotification(notification: Notification) {
    return {
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      data: notification.data,
      readAt: notification.readAt,
      createdAt: notification.createdAt,
    };
  }

  private postgresCode(error: unknown): string | undefined {
    return typeof error === 'object' && error !== null && 'code' in error && typeof error.code === 'string'
      ? error.code
      : undefined;
  }
}
