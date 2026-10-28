import { ConflictException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource, EntityManager, In, IsNull } from 'typeorm';
import { OfferStatus } from '../common/enums/offer-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { OrderOffer } from './order-offer.entity';
import { Order } from './order.entity';
import { RealtimePublisher } from '../realtime/realtime-publisher.port';
import { canTransitionOrder } from './domain/order-transition.policy';

interface CandidateRow {
  id: number;
}

@Injectable()
export class MatchingService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly config: ConfigService,
    @Optional() private readonly realtime?: RealtimePublisher,
  ) {}

  async matchLockedOrder(manager: EntityManager, order: Order): Promise<OrderOffer[]> {
    if (order.status !== OrderStatus.PENDING_MATCH && order.status !== OrderStatus.OFFERED) {
      throw new ConflictException('Order is not waiting for matching');
    }
    const [longitude, latitude] = order.customerLocation.coordinates;
    const radiusMeters = this.config.getOrThrow<number>('MATCH_RADIUS_KM') * 1000;
    const maxAgeSeconds = this.config.getOrThrow<number>('PROVIDER_LOCATION_MAX_AGE_SECONDS');
    const candidates = (await manager.query(
        `
        SELECT p.id
        FROM providers p
        INNER JOIN users u ON u.id = p.user_id
        WHERE p.approval_status = 'APPROVED'
          AND p.is_online = true
          AND u.status = 'ACTIVE'
          AND p.current_location IS NOT NULL
          AND p.last_seen_at > clock_timestamp() - ($4::int * interval '1 second')
          AND ST_DWithin(
            p.current_location,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
            $3
          )
          AND NOT EXISTS (
            SELECT 1 FROM order_offers previous
            WHERE previous.order_id = $5 AND previous.provider_id = p.id
          )
          AND NOT EXISTS (
            SELECT 1 FROM order_offers pending
            WHERE pending.provider_id = p.id AND pending.status = 'PENDING'
          )
          AND NOT EXISTS (
            SELECT 1 FROM orders active_order
            WHERE active_order.provider_id = p.id
              AND active_order.status IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'AWAITING_PRICE_APPROVAL', 'PRICE_DISPUTED', 'AWAITING_PAYMENT', 'PAID')
          )
        ORDER BY ST_Distance(
          p.current_location,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) ASC, p.id ASC
        FOR UPDATE OF p SKIP LOCKED
      `,
        [longitude, latitude, radiusMeters, maxAgeSeconds, order.id],
      )) as CandidateRow[];

    if (candidates.length === 0) return [];
    const offers: OrderOffer[] = [];
    const ttlSeconds = this.config.getOrThrow<number>('OFFER_TTL_SECONDS');
    for (const candidate of candidates) {
      const [{ busy }] = (await manager.query(
        `SELECT EXISTS (
          SELECT 1 FROM order_offers WHERE provider_id = $1 AND status = 'PENDING'
        ) OR EXISTS (
          SELECT 1 FROM orders WHERE provider_id = $1
            AND status IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'AWAITING_PRICE_APPROVAL', 'PRICE_DISPUTED', 'AWAITING_PAYMENT', 'PAID')
        ) AS busy`,
        [candidate.id],
      )) as Array<{ busy: boolean }>;
      if (busy) continue;

      const offer = await manager.getRepository(OrderOffer).save(
        manager.getRepository(OrderOffer).create({
          orderId: order.id,
          providerId: candidate.id,
          status: OfferStatus.PENDING,
          expiresAt: new Date(Date.now() + ttlSeconds * 1000),
        }),
      );
      offers.push(offer);
    }
    if (offers.length > 0) {
      order.status = OrderStatus.OFFERED;
      await manager.getRepository(Order).save(order);
    }
    return offers;
  }

  async retry(orderId: number, customerId: number): Promise<{ order: Order; offers: OrderOffer[] }> {
    return this.dataSource.transaction(async (manager) => {
      const order = await manager.getRepository(Order).findOne({
        where: { id: orderId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!order || order.customerId !== customerId) throw new NotFoundException('Order not found');
      const offers = await this.matchLockedOrder(manager, order);
      return { order, offers };
    });
  }

  /**
   * Re-run matching when a provider becomes available. Payment/webhook
   * matching may have happened before any provider was online, leaving the
   * paid order in PENDING_MATCH. This closes that timing gap without creating
   * a second offer for an order that has already been matched.
   */
  async matchPendingOrders(): Promise<void> {
    const pending = await this.dataSource.getRepository(Order).find({
      where: {
        status: In([OrderStatus.PENDING_MATCH, OrderStatus.OFFERED]),
        providerId: IsNull(),
      },
      order: { createdAt: 'ASC', id: 'ASC' },
      take: 30,
    });

    for (const candidate of pending) {
      const result = await this.retry(candidate.id, candidate.customerId);
      if (result.offers.length === 0) continue;
      await this.realtime?.orderStatusChanged(result.order.id, result.order.status);
      for (const offer of result.offers) {
        await this.realtime?.offerCreated(
          offer.providerId,
          result.order.id,
          offer.id,
          offer.expiresAt,
        );
      }
    }
  }

  /**
   * Called after one broadcast offer is rejected or expires. While another
   * provider still holds a live offer the order stays OFFERED; only when none
   * remain does it reopen matching (which may broadcast to new providers).
   */
  async releaseOffer(manager: EntityManager, order: Order): Promise<OrderOffer[]> {
    const stillPending = await manager
      .getRepository(OrderOffer)
      .countBy({ orderId: order.id, status: OfferStatus.PENDING });
    if (stillPending > 0 || !canTransitionOrder(order.status, OrderStatus.PENDING_MATCH)) {
      return [];
    }
    order.status = OrderStatus.PENDING_MATCH;
    await manager.getRepository(Order).save(order);
    return this.matchLockedOrder(manager, order);
  }

  async expireOffer(offerId: number): Promise<void> {
    const event = await this.dataSource.transaction(async (manager) => {
      const found = await manager.getRepository(OrderOffer).findOneBy({ id: offerId });
      if (!found) return null;
      const order = await manager.getRepository(Order).findOne({
        where: { id: found.orderId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!order) return null;
      const offer = await manager.getRepository(OrderOffer).findOne({
        where: { id: offerId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!offer || offer.status !== OfferStatus.PENDING) return null;
      const [{ expired }] = (await manager.query(
        'SELECT expires_at <= clock_timestamp() AS expired FROM order_offers WHERE id = $1',
        [offer.id],
      )) as Array<{ expired: boolean }>;
      if (!expired) return null;
      offer.status = OfferStatus.EXPIRED;
      await manager.getRepository(OrderOffer).save(offer);
      const nextOffers = await this.releaseOffer(manager, order);
      return { orderId: order.id, providerId: offer.providerId, offerId: offer.id, status: order.status, nextOffers };
    });
    if (!event) return;
    await this.realtime?.offerExpired(event.providerId, event.orderId, event.offerId);
    await this.realtime?.orderStatusChanged(event.orderId, event.status);
    for (const next of event.nextOffers) {
      await this.realtime?.offerCreated(next.providerId, event.orderId, next.id, next.expiresAt);
    }
  }
}
