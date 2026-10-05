import { Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, In } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { Provider } from '../providers/provider.entity';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { Message } from './message.entity';

@Injectable()
export class MessagesService {
  constructor(private readonly database: DataSource, private readonly realtime: RealtimeGateway) {}

  private async participant(orderId: number, userId: number): Promise<Order> {
    const order = await this.database.getRepository(Order).findOneBy({
      id: orderId,
      status: In([OrderStatus.ACCEPTED, OrderStatus.ARRIVED, OrderStatus.IN_PROGRESS, OrderStatus.AWAITING_PAYMENT]),
    });
    if (!order) throw new NotFoundException('Active order not found');
    if (order.customerId === userId) return order;
    const provider = await this.database.getRepository(Provider).findOneBy({ userId });
    if (!provider || provider.id !== order.providerId) throw new NotFoundException('Active order not found');
    return order;
  }

  async list(orderId: number, userId: number) {
    await this.participant(orderId, userId);
    const items = await this.database.getRepository(Message).find({
      where: { orderId }, order: { id: 'DESC' }, take: 100,
    });
    return items.reverse().map(({ id, senderId, content, createdAt }) => ({ id, senderId, content, createdAt }));
  }

  async create(orderId: number, userId: number, content: string) {
    await this.participant(orderId, userId);
    const saved = await this.database.getRepository(Message).save(
      this.database.getRepository(Message).create({ orderId, senderId: userId, content: content.trim() }),
    );
    const result = { id: saved.id, senderId: saved.senderId, content: saved.content, createdAt: saved.createdAt };
    this.realtime.messageCreated(orderId, result);
    return result;
  }
}
