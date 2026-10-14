import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { Provider } from '../providers/provider.entity';
import { CreateReviewDto } from './dto/create-review.dto';
import { Review } from './review.entity';

@Injectable()
export class ReviewsService {
  constructor(private readonly database: DataSource) {}

  private async participants(orderId: number, userId: number) {
    const order = await this.database.getRepository(Order).findOneBy({ id: orderId });
    if (!order?.providerId) throw new NotFoundException('Order not found');
    const provider = await this.database.getRepository(Provider).findOneBy({ id: order.providerId });
    if (!provider || (userId !== order.customerId && userId !== provider.userId)) {
      throw new NotFoundException('Order not found');
    }
    return { order, provider };
  }

  async create(orderId: number, reviewerId: number, dto: CreateReviewDto) {
    const { order, provider } = await this.participants(orderId, reviewerId);
    if (order.status !== OrderStatus.COMPLETED) throw new ConflictException('Reviews require a completed order');
    const revieweeId = reviewerId === order.customerId ? provider.userId : order.customerId;
    try {
      const review = await this.database.getRepository(Review).save(this.database.getRepository(Review).create({
        orderId, reviewerId, revieweeId, rating: dto.rating, comment: dto.comment?.trim() || null,
      }));
      return { id: review.id, orderId, reviewerId, revieweeId, rating: review.rating, comment: review.comment, createdAt: review.createdAt };
    } catch (error) {
      if (error instanceof Error && 'code' in error && error.code === '23505') {
        throw new ConflictException('You already reviewed this order');
      }
      throw error;
    }
  }

  async list(orderId: number, userId: number) {
    const { order } = await this.participants(orderId, userId);
    if (order.status !== OrderStatus.COMPLETED) throw new ConflictException('Reviews require a completed order');
    return this.database.getRepository(Review).find({
      where: { orderId }, order: { createdAt: 'ASC', id: 'ASC' },
      select: { id: true, orderId: true, reviewerId: true, revieweeId: true, rating: true, comment: true, createdAt: true },
    });
  }
}
