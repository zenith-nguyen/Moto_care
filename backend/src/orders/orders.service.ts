import { ConflictException, ForbiddenException, Injectable, NotFoundException, Optional } from '@nestjs/common';
import { DataSource, EntityManager } from 'typeorm';
import { createHmac, randomUUID, timingSafeEqual } from 'node:crypto';
import { ConfigService } from '@nestjs/config';
import { ApprovalStatus } from '../common/enums/approval-status.enum';
import { OfferStatus } from '../common/enums/offer-status.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PaymentStatus } from '../common/enums/payment-status.enum';
import { UserStatus } from '../common/enums/user-status.enum';
import { IncidentType } from '../incident-types/incident-type.entity';
import { Provider } from '../providers/provider.entity';
import { OrderPricingService } from '../pricing/order-pricing.service';
import { Payment } from '../payments/payment.entity';
import { Wallet } from '../payments/wallet.entity';
import { WalletTransaction } from '../payments/wallet-transaction.entity';
import { WalletTransactionType } from '../common/enums/wallet-transaction-type.enum';
import { RealtimePublisher } from '../realtime/realtime-publisher.port';
import { User } from '../users/user.entity';
import { CreateOrderDto } from './dto/create-order.dto';
import { MatchingService } from './matching.service';
import { OrderOffer } from './order-offer.entity';
import { Order } from './order.entity';
import { PaymentAdjustment } from '../payments/payment-adjustment.entity';
import { PaymentAdjustmentStatus, PaymentAdjustmentType } from '../common/enums/payment-adjustment.enum';
import { moneyToCents } from '../common/utils/money';
import { canTransitionOrder } from './domain/order-transition.policy';
import { presentOrderMatch } from './presentation/order.presenter';

@Injectable()
export class OrdersService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly matching: MatchingService,
    private readonly config: ConfigService,
    private readonly pricing: OrderPricingService,
    @Optional() private readonly realtime?: RealtimePublisher,
  ) {}

  async create(customerId: number, dto: CreateOrderDto) {
    const [customer, incident] = await Promise.all([
      this.dataSource.getRepository(User).findOneBy({ id: customerId }),
      this.dataSource.getRepository(IncidentType).findOneBy({ id: dto.incident_type_id, isActive: true }),
    ]);
    if (!customer || customer.status !== UserStatus.ACTIVE) {
      throw new ForbiddenException('Customer account is not active');
    }
    if (!incident) throw new NotFoundException('Active incident type not found');
    const weather = await this.pricing.weatherAt(dto.customer_location.latitude, dto.customer_location.longitude);

    return this.dataSource.transaction(async (manager) => {
      const currentCustomer = await manager.getRepository(User).findOneBy({ id: customerId });
      if (!currentCustomer || currentCustomer.status !== UserStatus.ACTIVE) {
        throw new ForbiddenException('Customer account is not active');
      }
      const currentIncident = await manager.getRepository(IncidentType).findOneBy({ id: dto.incident_type_id, isActive: true });
      if (!currentIncident) throw new NotFoundException('Active incident type not found');
      const quote = this.pricing.quote(currentIncident.basePrice, weather);

      const order = await manager.getRepository(Order).save(
        manager.getRepository(Order).create({
          code: `MC-${randomUUID().replaceAll('-', '').slice(0, 20)}`,
          customerId,
          incidentTypeId: currentIncident.id,
          status: OrderStatus.AWAITING_PREPAYMENT,
          customerLocation: {
            type: 'Point',
            coordinates: [dto.customer_location.longitude, dto.customer_location.latitude],
          },
          basePrice: quote.basePrice,
          estimatedPrice: quote.estimatedPrice,
          weatherSurcharge: quote.weatherSurcharge,
          weatherMultiplier: quote.weatherMultiplier,
          weatherCategory: quote.weather.category,
          weatherSource: quote.weather.source,
          weatherObservedAt: quote.weather.observedAt,
          weatherCode: quote.weather.weatherCode,
          weatherPrecipitationMm: this.measurement(quote.weather.precipitationMm),
          weatherWindSpeedKmh: this.measurement(quote.weather.windSpeedKmh),
          weatherWindGustKmh: this.measurement(quote.weather.windGustKmh),
          extraCost: '0.00',
        }),
      );
      await manager.getRepository(Payment).save(
        manager.getRepository(Payment).create({
          orderId: order.id,
          amount: order.estimatedPrice,
          status: PaymentStatus.PENDING,
          isDemo: false,
        }),
      );
      return presentOrderMatch(order, null);
    });
  }

  async cancel(orderId: number, customerId: number, reason: string) {
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      if (order.customerId !== customerId) throw new NotFoundException('Order not found');
      const payment = await manager.getRepository(Payment).findOne({
        where: { orderId }, lock: { mode: 'pessimistic_write' }, order: { id: 'ASC' },
      });
      const targetStatus = payment?.status === PaymentStatus.PAID
        ? OrderStatus.REFUND_PENDING
        : OrderStatus.CANCELLED;
      if (!canTransitionOrder(order.status, targetStatus)) {
        throw new ConflictException('Order requires admin review or is already closed');
      }
      if (order.status === OrderStatus.OFFERED) {
        await manager.getRepository(OrderOffer).update(
          { orderId, status: OfferStatus.PENDING }, { status: OfferStatus.EXPIRED },
        );
      }
      order.cancelReason = reason;
      order.cancelledById = customerId;
      if (payment?.status === PaymentStatus.PAID) {
        payment.status = PaymentStatus.REFUND_PENDING;
        order.status = targetStatus;
        await manager.getRepository(Payment).save(payment);
      } else {
        if (payment) {
          payment.status = PaymentStatus.CANCELLED;
          await manager.getRepository(Payment).save(payment);
        }
        order.status = targetStatus;
      }
      await manager.getRepository(Order).save(order);
      return { orderId: order.id, status: order.status, refundAmount: payment?.status === PaymentStatus.REFUND_PENDING ? payment.amount : null };
    });
    this.realtime?.orderStatusChanged(orderId, result.status);
    return result;
  }

  async retry(orderId: number, customerId: number) {
    const { order, offer } = await this.matching.retry(orderId, customerId);
    if (offer) this.realtime?.offerCreated(offer.providerId, order.id, offer.id, offer.expiresAt);
    return presentOrderMatch(order, offer);
  }

  async accept(orderId: number, offerId: number, userId: number) {
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      const provider = await this.lockOwnProvider(manager, userId);
      const offer = await this.lockOffer(manager, orderId, offerId, provider.id);
      if (!canTransitionOrder(order.status, OrderStatus.ACCEPTED) || offer.status !== OfferStatus.PENDING) {
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
         AND status IN ('ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'AWAITING_PRICE_APPROVAL', 'PRICE_DISPUTED', 'AWAITING_PAYMENT', 'PAID') LIMIT 1`,
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
    this.realtime?.orderStatusChanged(orderId, result.status);
    return result;
  }

  async reject(orderId: number, offerId: number, userId: number) {
    const { response, nextOffer } = await this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      const provider = await this.lockOwnProvider(manager, userId);
      const offer = await this.lockOffer(manager, orderId, offerId, provider.id);
      if (!canTransitionOrder(order.status, OrderStatus.PENDING_MATCH) || offer.status !== OfferStatus.PENDING) {
        throw new ConflictException('Offer is no longer available');
      }
      offer.status = OfferStatus.REJECTED;
      await manager.getRepository(OrderOffer).save(offer);
      order.status = OrderStatus.PENDING_MATCH;
      await manager.getRepository(Order).save(order);
      const nextOffer = await this.matching.matchLockedOrder(manager, order);
      return { response: { orderId: order.id, offerStatus: offer.status, ...presentOrderMatch(order, nextOffer) }, nextOffer };
    });
    this.realtime?.orderStatusChanged(orderId, response.status);
    if (nextOffer) this.realtime?.offerCreated(nextOffer.providerId, orderId, nextOffer.id, nextOffer.expiresAt);
    return response;
  }

  async arrive(orderId: number, providerUserId: number) {
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      const provider = await this.lockOwnProvider(manager, providerUserId);
      if (order.providerId !== provider.id) throw new NotFoundException('Order not found');
      if (!canTransitionOrder(order.status, OrderStatus.ARRIVED)) {
        throw new ConflictException('Order is not awaiting arrival');
      }
      order.status = OrderStatus.ARRIVED;
      await manager.getRepository(Order).save(order);
      return { orderId, status: order.status };
    });
    this.realtime?.orderStatusChanged(orderId, result.status);
    return result;
  }

  async startToken(orderId: number, customerId: number) {
    const order = await this.dataSource.getRepository(Order).findOneBy({ id: orderId, customerId });
    if (!order) throw new NotFoundException('Order not found');
    if (order.status !== OrderStatus.ARRIVED) throw new ConflictException('Provider has not arrived');
    const expiresAt = Date.now() + 5 * 60_000;
    const signature = this.startSignature(order.id, customerId, expiresAt);
    return { orderId, token: `${expiresAt}.${signature}`, expiresAt: new Date(expiresAt) };
  }

  async start(orderId: number, providerUserId: number, token: string) {
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      const provider = await this.lockOwnProvider(manager, providerUserId);
      if (order.providerId !== provider.id) throw new NotFoundException('Order not found');
      if (!canTransitionOrder(order.status, OrderStatus.IN_PROGRESS)) {
        throw new ConflictException('Order cannot start now');
      }
      const [expiryText, signature, extra] = token.split('.');
      const expiresAt = Number(expiryText);
      if (extra || !Number.isSafeInteger(expiresAt) || expiresAt <= Date.now() || !/^[0-9a-f]{64}$/.test(signature ?? '')) {
        throw new ForbiddenException('Invalid or expired start token');
      }
      const expected = Buffer.from(this.startSignature(order.id, order.customerId, expiresAt), 'hex');
      if (!timingSafeEqual(Buffer.from(signature, 'hex'), expected)) {
        throw new ForbiddenException('Invalid or expired start token');
      }
      order.status = OrderStatus.IN_PROGRESS;
      await manager.getRepository(Order).save(order);
      return { orderId, status: order.status };
    });
    this.realtime?.orderStatusChanged(orderId, result.status);
    return result;
  }

  async complete(orderId: number, providerUserId: number) {
    const result = await this.dataSource.transaction(async (manager) => {
      const order = await this.lockOrder(manager, orderId);
      const provider = await this.lockOwnProvider(manager, providerUserId);
      if (order.providerId !== provider.id) throw new NotFoundException('Order not found');
      if (!canTransitionOrder(order.status, OrderStatus.COMPLETED) || !order.finalPrice) {
        throw new ConflictException('Final price and payment adjustment must be settled before completion');
      }
      const payment = await manager.getRepository(Payment).findOne({
        where: { orderId }, lock: { mode: 'pessimistic_write' }, order: { id: 'ASC' },
      });
      if (!payment?.isDemo || payment.status !== PaymentStatus.PAID || payment.amount !== order.estimatedPrice) {
        throw new ConflictException('Only a paid demo order can be completed');
      }
      const adjustment = await manager.getRepository(PaymentAdjustment).findOne({
        where: { orderId }, lock: { mode: 'pessimistic_write' },
      });
      const prepaid = moneyToCents(payment.amount);
      const expectedFinal = adjustment
        ? adjustment.type === PaymentAdjustmentType.CHARGE
          ? prepaid + moneyToCents(adjustment.amount)
          : prepaid - moneyToCents(adjustment.amount)
        : prepaid;
      if (expectedFinal < 0n || moneyToCents(order.finalPrice) !== expectedFinal) {
        throw new ConflictException('Final price does not reconcile with payment records');
      }
      if (adjustment && (!adjustment.isDemo || adjustment.status !== PaymentAdjustmentStatus.SETTLED)) {
        throw new ConflictException('Payment adjustment is not settled');
      }
      await manager.query('INSERT INTO wallets (provider_id, balance) VALUES ($1, 0) ON CONFLICT (provider_id) DO NOTHING', [provider.id]);
      const wallet = await manager.getRepository(Wallet).findOne({
        where: { providerId: provider.id }, lock: { mode: 'pessimistic_write' },
      });
      if (!wallet) throw new ConflictException('Provider wallet unavailable');
      await manager.query('UPDATE wallets SET balance = balance + $1::numeric WHERE id = $2', [order.finalPrice, wallet.id]);
      await manager.getRepository(WalletTransaction).save(manager.getRepository(WalletTransaction).create({
        walletId: wallet.id, type: WalletTransactionType.CREDIT, amount: order.finalPrice, orderId,
      }));
      order.status = OrderStatus.COMPLETED;
      await manager.getRepository(Order).save(order);
      return { orderId, status: order.status, finalPrice: order.finalPrice, settlement: 'DEMO_ONLY' };
    });
    this.realtime?.orderStatusChanged(orderId, result.status);
    return result;
  }

  private startSignature(orderId: number, customerId: number, expiresAt: number): string {
    const secret = this.config.get<string>('ORDER_START_HMAC_SECRET')
      ?? this.config.getOrThrow<string>('JWT_SECRET');
    return createHmac('sha256', secret)
      .update(`motocare:start:${orderId}:${customerId}:${expiresAt}`)
      .digest('hex');
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

  private measurement(value: number | null): string | null {
    return value === null ? null : value.toFixed(2);
  }

}
