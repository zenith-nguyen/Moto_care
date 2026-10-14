import { Injectable, Logger } from '@nestjs/common';
import { NotificationsService } from '../notifications/notifications.service';
import { OrderStatus } from '../common/enums/order-status.enum';
import { RealtimeGateway } from './realtime.gateway';
import { RealtimeMessagePayload, RealtimePublisher } from './realtime-publisher.port';

@Injectable()
export class RealtimeNotificationPublisher implements RealtimePublisher {
  private readonly logger = new Logger(RealtimeNotificationPublisher.name);

  constructor(
    private readonly realtime: RealtimeGateway,
    private readonly notifications: NotificationsService,
  ) {}

  async providerLocation(orderId: number, providerId: number, latitude: number, longitude: number, updatedAt: Date): Promise<void> {
    this.realtime.providerLocation(orderId, providerId, latitude, longitude, updatedAt);
    await this.safely('provider-nearby', () => this.notifications.notifyProviderNearbyIfWithin(orderId, providerId));
  }

  async messageCreated(orderId: number, message: RealtimeMessagePayload): Promise<void> {
    this.realtime.messageCreated(orderId, message);
    await this.safely('message-created', () =>
      this.notifications.notifyMessageCreated(orderId, message.senderId, message.id));
  }

  async offerCreated(providerId: number, orderId: number, offerId: number, expiresAt: Date): Promise<void> {
    this.realtime.offerCreated(providerId, orderId, offerId, expiresAt);
    await this.safely('offer-created', () =>
      this.notifications.notifyOfferCreated(providerId, orderId, offerId, expiresAt));
  }

  async offerExpired(providerId: number, orderId: number, offerId: number): Promise<void> {
    this.realtime.offerExpired(providerId, orderId, offerId);
    await this.safely('offer-expired', () =>
      this.notifications.notifyOfferExpired(providerId, orderId, offerId));
  }

  async orderStatusChanged(orderId: number, status: OrderStatus): Promise<void> {
    this.realtime.orderStatusChanged(orderId, status);
    await this.safely('order-status-changed', () =>
      this.notifications.notifyOrderStatusChanged(orderId, status));
  }

  private async safely(name: string, action: () => Promise<void>): Promise<void> {
    try {
      await action();
    } catch {
      this.logger.error(`Notification fan-out failed for ${name}`);
    }
  }
}
