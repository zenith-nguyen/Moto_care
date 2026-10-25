import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { OrderStatus } from '../common/enums/order-status.enum';
import { Order } from '../orders/order.entity';
import { Provider } from '../providers/provider.entity';
import { IncidentPhotoStorageService } from './incident-photo-storage.service';
import { OrderPhoto } from './order-photo.entity';

const MAX_PHOTOS_PER_ORDER = 6;

// Terminal states where new incident photos no longer make sense.
const CLOSED_STATUSES = new Set<OrderStatus>([
  OrderStatus.COMPLETED,
  OrderStatus.CANCELLED,
  OrderStatus.REFUND_PENDING,
  OrderStatus.REFUNDED,
]);

@Injectable()
export class OrderPhotosService {
  constructor(
    private readonly database: DataSource,
    private readonly storage: IncidentPhotoStorageService,
  ) {}

  // Resolves the order and asserts the caller is a participant (its customer or
  // the assigned provider). Mirrors ReviewsService participant checks.
  private async participant(orderId: number, userId: number) {
    const order = await this.database
      .getRepository(Order)
      .findOneBy({ id: orderId });
    if (!order) throw new NotFoundException('Order not found');
    let isProvider = false;
    if (order.providerId) {
      const provider = await this.database
        .getRepository(Provider)
        .findOneBy({ id: order.providerId });
      isProvider = provider?.userId === userId;
    }
    const isCustomer = order.customerId === userId;
    if (!isCustomer && !isProvider) {
      throw new NotFoundException('Order not found');
    }
    return { order, isCustomer, isProvider };
  }

  async add(orderId: number, userId: number, file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('An image file is required');
    const { order, isCustomer } = await this.participant(orderId, userId);
    if (!isCustomer) {
      throw new ForbiddenException('Only the customer can add incident photos');
    }
    if (CLOSED_STATUSES.has(order.status)) {
      throw new ConflictException('Order no longer accepts incident photos');
    }
    const existing = await this.database
      .getRepository(OrderPhoto)
      .countBy({ orderId });
    if (existing >= MAX_PHOTOS_PER_ORDER) {
      throw new ConflictException(
        `An order can hold at most ${MAX_PHOTOS_PER_ORDER} photos`,
      );
    }

    const stored = await this.storage.save(file);
    try {
      const repository = this.database.getRepository(OrderPhoto);
      const photo = await repository.save(
        repository.create({
          orderId,
          uploadedById: userId,
          storageKey: stored.storageKey,
          mimeType: stored.mimeType,
          sizeBytes: stored.sizeBytes,
        }),
      );
      return this.toMetadata(photo);
    } catch (error) {
      // Never leave an orphaned blob if the row fails to persist.
      await this.storage.remove(stored.storageKey);
      throw error;
    }
  }

  async list(orderId: number, userId: number) {
    await this.participant(orderId, userId);
    const photos = await this.database.getRepository(OrderPhoto).find({
      where: { orderId },
      order: { createdAt: 'ASC', id: 'ASC' },
    });
    return photos.map((photo) => this.toMetadata(photo));
  }

  async image(orderId: number, photoId: number, userId: number) {
    await this.participant(orderId, userId);
    const photo = await this.database
      .getRepository(OrderPhoto)
      .findOneBy({ id: photoId, orderId });
    if (!photo) throw new NotFoundException('Incident photo not found');
    const data = await this.storage.read(photo.storageKey);
    return { data, mimeType: photo.mimeType, sizeBytes: photo.sizeBytes };
  }

  private toMetadata(photo: OrderPhoto) {
    return {
      id: photo.id,
      orderId: photo.orderId,
      uploadedById: photo.uploadedById,
      mimeType: photo.mimeType,
      sizeBytes: photo.sizeBytes,
      createdAt: photo.createdAt,
    };
  }
}
