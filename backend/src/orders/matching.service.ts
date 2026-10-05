import { ConflictException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource, EntityManager } from 'typeorm';
import { OfferStatus } from '../common/enums/offer-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { OrderOffer } from './order-offer.entity';
import { Order } from './order.entity';
import { RealtimeGateway } from '../realtime/realtime.gateway';

interface CandidateRow {
  id: number;
}

@Injectable()
export class MatchingService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly config: ConfigService,
    @Optional() private readonly realtime?: RealtimeGateway,
  ) {}

  async matchLockedOrder(manager: EntityManager, order: Order): Promise<OrderOffer | null> {
    if (order.status !== OrderStatus.PENDING_MATCH) {
      throw new ConflictException('Order is not waiting for matching');
    }
    const [longitude, latitude] = order.customerLocation.coordinates;
    const radiusMeters = this.config.getOrThrow<number>('MATCH_RADIUS_KM') * 1000;
    const maxAgeSeconds = this.config.getOrThrow<number>('PROVIDER_LOCATION_MAX_AGE_SECONDS');
    const triedProviderIds: number[] = [];
    while (true) {
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
              AND active_order.status IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'AWAITING_PAYMENT', 'PAID')
          )
          AND NOT (p.id = ANY($6::int[]))
        ORDER BY ST_Distance(
          p.current_location,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) ASC, p.id ASC
        LIMIT 1
        FOR UPDATE OF p SKIP LOCKED
      `,
        [longitude, latitude, radiusMeters, maxAgeSeconds, order.id, triedProviderIds],
      )) as CandidateRow[];

      if (candidates.length === 0) return null;
      const providerId = candidates[0].id;
      triedProviderIds.push(providerId);

      // A fresh READ COMMITTED statement is needed after locking the provider:
      // another matching transaction may have committed an offer while this query waited.
      const [{ busy }] = (await manager.query(
        `SELECT EXISTS (
          SELECT 1 FROM order_offers WHERE provider_id = $1 AND status = 'PENDING'
        ) OR EXISTS (
          SELECT 1 FROM orders WHERE provider_id = $1
            AND status IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'AWAITING_PAYMENT', 'PAID')
        ) AS busy`,
        [providerId],
      )) as Array<{ busy: boolean }>;
      if (busy) continue;

      const ttlSeconds = this.config.getOrThrow<number>('OFFER_TTL_SECONDS');
      const offer = await manager.getRepository(OrderOffer).save(
        manager.getRepository(OrderOffer).create({
          orderId: order.id,
          providerId,
          status: OfferStatus.PENDING,
          expiresAt: new Date(Date.now() + ttlSeconds * 1000),
        }),
      );
      order.status = OrderStatus.OFFERED;
      await manager.getRepository(Order).save(order);
      return offer;
    }
  }

  async retry(orderId: number, customerId: number): Promise<{ order: Order; offer: OrderOffer | null }> {
    return this.dataSource.transaction(async (manager) => {
      const order = await manager.getRepository(Order).findOne({
        where: { id: orderId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!order || order.customerId !== customerId) throw new NotFoundException('Order not found');
      const offer = await this.matchLockedOrder(manager, order);
      return { order, offer };
    });
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
      if (order.status === OrderStatus.OFFERED) {
        order.status = OrderStatus.PENDING_MATCH;
        await manager.getRepository(Order).save(order);
        const nextOffer = await this.matchLockedOrder(manager, order);
        return { orderId: order.id, providerId: offer.providerId, offerId: offer.id, status: order.status, nextOffer };
      }
      return { orderId: order.id, providerId: offer.providerId, offerId: offer.id, status: order.status, nextOffer: null };
    });
    if (!event) return;
    this.realtime?.offerExpired(event.providerId, event.orderId, event.offerId);
    this.realtime?.orderStatusChanged(event.orderId, event.status);
    if (event.nextOffer) {
      this.realtime?.offerCreated(event.nextOffer.providerId, event.orderId, event.nextOffer.id, event.nextOffer.expiresAt);
    }
  }
}
