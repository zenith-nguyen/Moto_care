import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { DataSource, EntityManager, MoreThan } from 'typeorm';
import { randomUUID } from 'node:crypto';
import { ApprovalStatus } from '../common/enums/approval-status.enum';
import { OfferStatus } from '../common/enums/offer-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { IncidentType } from '../incident-types/incident-type.entity';
import { Provider } from '../providers/provider.entity';
import { User } from '../users/user.entity';
import { CreateOrderDto } from './dto/create-order.dto';
import { MatchingService } from './matching.service';
import { OrderOffer } from './order-offer.entity';
import { Order } from './order.entity';

@Injectable()
export class OrdersService {
  constructor(private readonly dataSource: DataSource, private readonly matching: MatchingService) {}

  async create(customerId: number, dto: CreateOrderDto) {
    return this.dataSource.transaction(async (manager) => {
      const customer = await manager.getRepository(User).findOneBy({ id: customerId });
      if (!customer || customer.status !== UserStatus.ACTIVE) {
        throw new ForbiddenException('Customer account is not active');
      }
      const incident = await manager.getRepository(IncidentType).findOneBy({ id: dto.incident_type_id, isActive: true });
      if (!incident) throw new NotFoundException('Active incident type not found');

      const order = await manager.getRepository(Order).save(
        manager.getRepository(Order).create({
          code: `MC-${randomUUID().replaceAll('-', '').slice(0, 20)}`,
          customerId,
          incidentTypeId: incident.id,
          status: OrderStatus.PENDING_MATCH,
          customerLocation: {
            type: 'Point',
            coordinates: [dto.customer_location.longitude, dto.customer_location.latitude],
          },
          estimatedPrice: incident.basePrice,
          extraCost: '0.00',
        }),
      );
      const offer = await this.matching.matchLockedOrder(manager, order);
      return this.formatMatchResult(order, offer);
    });
  }

  async getById(orderId: number, userId: number) {
    const order = await this.dataSource.getRepository(Order).findOne({
      where: { id: orderId },
      relations: { incidentType: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    if (order.customerId !== userId) {
      const provider = await this.dataSource.getRepository(Provider).findOneBy({ userId });
      if (!provider) throw new NotFoundException('Order not found');
      const pendingOffer = await this.dataSource.getRepository(OrderOffer).findOne({
        where: { orderId, providerId: provider.id, status: OfferStatus.PENDING, expiresAt: MoreThan(new Date()) },
      });
      if (order.providerId !== provider.id && !pendingOffer) {
        throw new NotFoundException('Order not found');
      }
    }
    return {
      id: order.id,
      code: order.code,
      status: order.status,
      customerId: order.customerId,
      providerId: order.providerId,
      incidentType: { id: order.incidentType.id, name: order.incidentType.name },
      customerLocation: order.customerLocation,
      estimatedPrice: order.estimatedPrice,
      extraCost: order.extraCost,
      finalPrice: order.finalPrice,
      message: order.status === OrderStatus.PENDING_MATCH ? 'No provider found yet; retry matching later' : null,
    };
  }

  async retry(orderId: number, customerId: number) {
    const { order, offer } = await this.matching.retry(orderId, customerId);
    return this.formatMatchResult(order, offer);
  }

  async accept(orderId: number, offerId: number, userId: number) {
    return this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      const provider = await this.lockOwnProvider(manager, userId);
      const offer = await this.lockOffer(manager, orderId, offerId, provider.id);
      if (order.status !== OrderStatus.OFFERED || offer.status !== OfferStatus.PENDING) {
        throw new ConflictException('Offer is no longer available');
      }
      const [{ valid }] = (await manager.query(
        'SELECT expires_at > clock_timestamp() AS valid FROM order_offers WHERE id = $1',
        [offer.id],
      )) as Array<{ valid: boolean }>;
      if (!valid) throw new ConflictException('Offer has expired');
      if (provider.approvalStatus !== ApprovalStatus.APPROVED || !provider.isOnline) {
        throw new ConflictException('Provider is not available');
      }
      const user = await manager.getRepository(User).findOneBy({ id: userId });
      if (!user || user.status !== UserStatus.ACTIVE) {
        throw new ConflictException('Provider account is not active');
      }
      const busy = (await manager.query(
        `SELECT 1 FROM orders WHERE provider_id = $1
         AND status IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'AWAITING_PAYMENT', 'PAID') LIMIT 1`,
        [provider.id],
      )) as unknown[];
      if (busy.length > 0) throw new ConflictException('Provider is already handling an order');

      offer.status = OfferStatus.ACCEPTED;
      order.providerId = provider.id;
      order.status = OrderStatus.ACCEPTED;
      await manager.getRepository(OrderOffer).save(offer);
      await manager.getRepository(Order).save(order);
      return { orderId: order.id, providerId: provider.id, status: order.status, offerStatus: offer.status };
    });
  }

  async reject(orderId: number, offerId: number, userId: number) {
    return this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      const provider = await this.lockOwnProvider(manager, userId);
      const offer = await this.lockOffer(manager, orderId, offerId, provider.id);
      if (order.status !== OrderStatus.OFFERED || offer.status !== OfferStatus.PENDING) {
        throw new ConflictException('Offer is no longer available');
      }
      offer.status = OfferStatus.REJECTED;
      await manager.getRepository(OrderOffer).save(offer);
      order.status = OrderStatus.PENDING_MATCH;
      await manager.getRepository(Order).save(order);
      const nextOffer = await this.matching.matchLockedOrder(manager, order);
      return { orderId: order.id, offerStatus: offer.status, ...this.formatMatchResult(order, nextOffer) };
    });
  }

  private async lockOrder(manager: EntityManager, orderId: number): Promise<Order> {
    const order = await manager.getRepository(Order).findOne({
      where: { id: orderId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  private async lockOwnProvider(manager: EntityManager, userId: number): Promise<Provider> {
    const provider = await manager.getRepository(Provider).findOne({
      where: { userId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!provider) throw new NotFoundException('Provider profile not found');
    return provider;
  }

  private async lockOffer(manager: EntityManager, orderId: number, offerId: number, providerId: number): Promise<OrderOffer> {
    const offer = await manager.getRepository(OrderOffer).findOne({
      where: { id: offerId, orderId, providerId },
      lock: { mode: 'pessimistic_write' },
    });
    if (!offer) throw new NotFoundException('Offer not found for this provider');
    return offer;
  }

  private formatMatchResult(order: Order, offer: OrderOffer | null) {
    return {
      id: order.id,
      code: order.code,
      status: order.status,
      estimatedPrice: order.estimatedPrice,
      matched: offer !== null,
      offerExpiresAt: offer?.expiresAt ?? null,
      message: offer ? null : 'No provider found yet; retry matching later',
    };
  }
}
