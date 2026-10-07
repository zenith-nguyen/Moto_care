import { OrderStatus } from '../common/enums/order-status.enum';

export type RealtimeMessagePayload = {
  id: number;
  senderId: number;
  content: string | null;
  image: { url: string; mimeType: string; sizeBytes: number } | null;
  createdAt: Date;
};

export abstract class RealtimePublisher {
  abstract providerLocation(
    orderId: number,
    providerId: number,
    latitude: number,
    longitude: number,
    updatedAt: Date,
  ): void;

  abstract messageCreated(orderId: number, message: RealtimeMessagePayload): void;
  abstract offerCreated(providerId: number, orderId: number, offerId: number, expiresAt: Date): void;
  abstract offerExpired(providerId: number, orderId: number, offerId: number): void;
  abstract orderStatusChanged(orderId: number, status: OrderStatus): void;
}
