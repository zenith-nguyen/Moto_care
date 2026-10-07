import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, In } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { Provider } from '../providers/provider.entity';
import { RealtimeMessagePayload, RealtimePublisher } from '../realtime/realtime-publisher.port';
import { ChatImageStorageService } from './chat-image-storage.service';
import { Message } from './message.entity';

const writableStatuses = [
  OrderStatus.ACCEPTED, OrderStatus.ARRIVED, OrderStatus.IN_PROGRESS, OrderStatus.AWAITING_PRICE_APPROVAL,
  OrderStatus.PRICE_DISPUTED, OrderStatus.AWAITING_PAYMENT, OrderStatus.PAID,
];

export type MessageResponse = RealtimeMessagePayload;

@Injectable()
export class MessagesService {
  constructor(
    private readonly database: DataSource,
    private readonly realtime: RealtimePublisher,
    private readonly imageStorage: ChatImageStorageService,
  ) {}

  private async participant(orderId: number, userId: number, statuses?: OrderStatus[]): Promise<Order> {
    const order = await this.database.getRepository(Order).findOneBy({
      id: orderId,
      ...(statuses ? { status: In(statuses) } : {}),
    });
    if (!order) throw new NotFoundException('Order not found');
    if (order.customerId === userId) return order;
    const provider = await this.database.getRepository(Provider).findOneBy({ userId });
    if (!provider || provider.id !== order.providerId) throw new NotFoundException('Order not found');
    return order;
  }

  async list(orderId: number, userId: number) {
    await this.participant(orderId, userId);
    const items = await this.database.getRepository(Message).find({
      where: { orderId }, order: { id: 'DESC' }, take: 100,
    });
    return items.reverse().map((message) => this.toResponse(message));
  }

  async create(orderId: number, userId: number, content?: string, image?: Express.Multer.File) {
    await this.participant(orderId, userId, writableStatuses);
    const normalizedContent = content?.trim() || null;
    if (!normalizedContent && !image) throw new BadRequestException('Message must contain text, an image, or both');
    const storedImage = image ? await this.imageStorage.save(image) : null;
    let saved: Message;
    try {
      saved = await this.database.getRepository(Message).save(
        this.database.getRepository(Message).create({
          orderId, senderId: userId, content: normalizedContent,
          imageStorageKey: storedImage?.storageKey ?? null,
          imageMimeType: storedImage?.mimeType ?? null,
          imageSizeBytes: storedImage?.sizeBytes ?? null,
        }),
      );
    } catch (error) {
      if (storedImage) await this.imageStorage.remove(storedImage.storageKey);
      throw error;
    }
    const result = this.toResponse(saved);
    this.realtime.messageCreated(orderId, result);
    return result;
  }

  async image(orderId: number, messageId: number, userId: number) {
    await this.participant(orderId, userId);
    const message = await this.database.getRepository(Message).findOneBy({ id: messageId, orderId });
    if (!message?.imageStorageKey || !message.imageMimeType || !message.imageSizeBytes) {
      throw new NotFoundException('Message image not found');
    }
    return {
      data: await this.imageStorage.read(message.imageStorageKey),
      mimeType: message.imageMimeType,
      sizeBytes: message.imageSizeBytes,
    };
  }

  private toResponse(message: Message): MessageResponse {
    const image = message.imageStorageKey && message.imageMimeType && message.imageSizeBytes
      ? { url: `/orders/${message.orderId}/messages/${message.id}/image`,
          mimeType: message.imageMimeType, sizeBytes: message.imageSizeBytes }
      : null;
    return { id: message.id, senderId: message.senderId, content: message.content, image, createdAt: message.createdAt };
  }
}
