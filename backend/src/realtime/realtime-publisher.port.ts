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
  ): Promise<void>;

  abstract messageCreated(orderId: number, message: RealtimeMessagePayload): Promise<void>;
  abstract offerCreated(providerId: number, orderId: number, offerId: number, expiresAt: Date): Promise<void>;
  abstract offerExpired(providerId: number, orderId: number, offerId: number): Promise<void>;
  abstract orderStatusChanged(orderId: number, status: OrderStatus): Promise<void>;
}
