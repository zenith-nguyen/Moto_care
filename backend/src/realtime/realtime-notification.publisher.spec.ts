import { Logger } from '@nestjs/common';
import { jest } from '@jest/globals';
import { OrderStatus } from '../common/enums/order-status.enum';
import { NotificationsService } from '../notifications/notifications.service';
import { RealtimeGateway } from './realtime.gateway';
import { RealtimeNotificationPublisher } from './realtime-notification.publisher';

describe('RealtimeNotificationPublisher', () => {
  const realtime = {
    providerLocation: jest.fn(),
    messageCreated: jest.fn(),
    offerCreated: jest.fn(),
    offerExpired: jest.fn(),
    orderStatusChanged: jest.fn(),
  };
  const notifications = {
    notifyProviderNearbyIfWithin: jest.fn<() => Promise<void>>(),
    notifyMessageCreated: jest.fn<() => Promise<void>>(),
    notifyOfferCreated: jest.fn<() => Promise<void>>(),
    notifyOfferExpired: jest.fn<() => Promise<void>>(),
    notifyOrderStatusChanged: jest.fn<() => Promise<void>>(),
  };
  let publisher: RealtimeNotificationPublisher;

  beforeEach(() => {
    jest.clearAllMocks();
    for (const method of Object.values(notifications)) method.mockResolvedValue();
    publisher = new RealtimeNotificationPublisher(
      realtime as unknown as RealtimeGateway,
      notifications as unknown as NotificationsService,
    );
  });

  it('publishes socket events immediately and fans out durable notifications', async () => {
    const expiresAt = new Date('2026-10-12T10:00:15.000Z');
    const updatedAt = new Date('2026-10-12T10:00:00.000Z');
    const message = { id: 8, senderId: 3, content: 'Tôi đang tới', image: null, createdAt: updatedAt };

    await publisher.offerCreated(2, 4, 6, expiresAt);
    await publisher.orderStatusChanged(4, OrderStatus.ACCEPTED);
    await publisher.providerLocation(4, 2, 10.7, 106.6, updatedAt);
    await publisher.messageCreated(4, message);

    expect(realtime.offerCreated).toHaveBeenCalledWith(2, 4, 6, expiresAt);
    expect(notifications.notifyOfferCreated).toHaveBeenCalledWith(2, 4, 6, expiresAt);
    expect(realtime.orderStatusChanged).toHaveBeenCalledWith(4, OrderStatus.ACCEPTED);
    expect(notifications.notifyOrderStatusChanged).toHaveBeenCalledWith(4, OrderStatus.ACCEPTED);
    expect(notifications.notifyProviderNearbyIfWithin).toHaveBeenCalledWith(4, 2);
    expect(notifications.notifyMessageCreated).toHaveBeenCalledWith(4, 3, 8);
  });

  it('does not let a push failure interrupt the realtime event', async () => {
    const errorLog = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
    notifications.notifyOfferExpired.mockRejectedValueOnce(new Error('provider unavailable'));

    await expect(publisher.offerExpired(2, 4, 6)).resolves.toBeUndefined();

    expect(realtime.offerExpired).toHaveBeenCalledWith(2, 4, 6);
    expect(errorLog).toHaveBeenCalledWith('Notification fan-out failed for offer-expired');
    errorLog.mockRestore();
  });
});
