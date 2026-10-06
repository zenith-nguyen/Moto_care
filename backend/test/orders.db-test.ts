import { BadRequestException, ConflictException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { jest } from '@jest/globals';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomUUID } from 'node:crypto';
import * as argon2 from 'argon2';
import { DataSource } from 'typeorm';
import { AdminService } from '../src/admin/admin.service';
import 'dotenv/config';
import { ApprovalStatus } from '../src/common/enums/approval-status.enum';
import { OfferStatus } from '../src/common/enums/offer-status.enum';
import { OrderStatus } from '../src/common/enums/order-status.enum';
import { UserRole } from '../src/common/enums/user-role.enum';
import { UserStatus } from '../src/common/enums/user-status.enum';
import { IncidentType } from '../src/incident-types/incident-type.entity';
import { MatchingService } from '../src/orders/matching.service';
import { OfferExpiryService } from '../src/orders/offer-expiry.service';
import { OrderOffer } from '../src/orders/order-offer.entity';
import { Order } from '../src/orders/order.entity';
import { Message } from '../src/messages/message.entity';
import { MessagesService } from '../src/messages/messages.service';
import { ChatImageStorageService } from '../src/messages/chat-image-storage.service';
import { RealtimeGateway } from '../src/realtime/realtime.gateway';
import { Socket } from 'socket.io';
import { PaymentStatus } from '../src/common/enums/payment-status.enum';
import { DemoPaymentsService } from '../src/payments/demo-payments.service';
import { Payment } from '../src/payments/payment.entity';
import { Wallet } from '../src/payments/wallet.entity';
import { WalletTransaction } from '../src/payments/wallet-transaction.entity';
import { WithdrawalRequest } from '../src/payments/withdrawal-request.entity';
import { WalletsController } from '../src/payments/wallets.controller';
import { Review } from '../src/reviews/review.entity';
import { ReviewsService } from '../src/reviews/reviews.service';
import { OrdersService } from '../src/orders/orders.service';
import { Provider } from '../src/providers/provider.entity';
import { ProvidersService } from '../src/providers/providers.service';
import { User } from '../src/users/user.entity';
import { UsersService } from '../src/users/users.service';
import { PasswordResetCode } from '../src/auth/password-reset-code.entity';
import { PasswordRecoveryService } from '../src/auth/password-recovery.service';
import { MailService } from '../src/auth/mail.service';
import { JwtStrategy } from '../src/auth/jwt.strategy';
import { OrderPricingService } from '../src/pricing/order-pricing.service';
import { WeatherFetcher, WeatherService } from '../src/pricing/weather.service';

const testDatabase = process.env.TEST_DATABASE_NAME;
if (!testDatabase || !/^motocare_[a-z0-9_]*test$/.test(testDatabase)) {
  throw new Error('Set TEST_DATABASE_NAME to a dedicated MotoCare test database');
}

describe('Orders and matching on PostGIS', () => {
  let database: DataSource;
  let orders: OrdersService;
  let matching: MatchingService;
  let demoPayments: DemoPaymentsService;
  let admin: AdminService;
  let messages: MessagesService;
  const messageCreated = jest.fn();
  const providerLocation = jest.fn();
  let providersService: ProvidersService;
  let passwordRecovery: PasswordRecoveryService;
  let deliveredCode: string | undefined;
  let incident: IncidentType;
  let customer: User;

  beforeAll(async () => {
    database = new DataSource({
      type: 'postgres',
      host: process.env.DATABASE_HOST,
      port: Number(process.env.DATABASE_PORT ?? 5432),
      username: process.env.DATABASE_USER,
      password: process.env.DATABASE_PASSWORD,
      database: testDatabase,
      entities: [User, Provider, IncidentType, Order, OrderOffer, Payment, Message, Wallet, WalletTransaction, WithdrawalRequest, Review, PasswordResetCode],
      synchronize: false,
      logging: false,
    });
    await database.initialize();
    const config = new ConfigService({
      MATCH_RADIUS_KM: 10,
      OFFER_TTL_SECONDS: 15,
      PROVIDER_LOCATION_MAX_AGE_SECONDS: 120,
      NODE_ENV: 'test',
      DEMO_MODE: true,
      JWT_SECRET: 'test-only-order-start-secret-longer-than-32-characters',
    });
    matching = new MatchingService(database, config);
    const weather = new WeatherService(config, (async () => {
      throw new Error('Weather fetch is disabled in database tests');
    }) satisfies WeatherFetcher);
    orders = new OrdersService(database, matching, config, new OrderPricingService(weather));
    demoPayments = new DemoPaymentsService(database, config, matching);
    admin = new AdminService(database);
    messages = new MessagesService(
      database, { messageCreated } as unknown as RealtimeGateway, new ChatImageStorageService(config),
    );
    providersService = new ProvidersService(
      database.getRepository(Provider),
      database.getRepository(OrderOffer),
      database.getRepository(User),
      config,
    );
    passwordRecovery = new PasswordRecoveryService(
      database,
      { sendPasswordResetCode: jest.fn(async (_email: string, code: string) => {
        deliveredCode = code;
        return true;
      }) } as unknown as MailService,
      config,
    );
  });

  beforeEach(async () => {
    await database.query('TRUNCATE TABLE users, incident_types RESTART IDENTITY CASCADE');
    customer = await makeUser(UserRole.CUSTOMER);
    deliveredCode = undefined;
    incident = await database.getRepository(IncidentType).save(
      database.getRepository(IncidentType).create({ code: 'FLAT_TIRE', name: 'Flat tire', basePrice: '100000.00', isActive: true }),
    );
  });

  afterAll(async () => {
    if (database?.isInitialized) await database.destroy();
  });

  async function makeUser(role: UserRole, status = UserStatus.ACTIVE): Promise<User> {
    return database.getRepository(User).save(
      database.getRepository(User).create({
        name: `${role} test`,
        email: `${randomUUID()}@motocare.test`,
        phone: null,
        passwordHash: 'test-only-hash',
        role,
        status,
      }),
    );
  }

  async function makeProvider(
    longitude: number,
    latitude: number,
    options: { approved?: boolean; online?: boolean; fresh?: boolean; active?: boolean } = {},
  ): Promise<{ user: User; provider: Provider }> {
    const user = await makeUser(UserRole.PROVIDER, options.active === false ? UserStatus.SUSPENDED : UserStatus.ACTIVE);
    const provider = await database.getRepository(Provider).save(
      database.getRepository(Provider).create({
        userId: user.id,
        approvalStatus: options.approved === false ? ApprovalStatus.PENDING : ApprovalStatus.APPROVED,
        isOnline: options.online !== false,
        currentLocation: { type: 'Point', coordinates: [longitude, latitude] },
        lastSeenAt: options.fresh === false ? new Date(Date.now() - 300_000) : new Date(),
      }),
    );
    return { user, provider };
  }

  async function createOrder() {
    const created = await orders.create(customer.id, {
      incident_type_id: incident.id,
      customer_location: { longitude: 106.7009, latitude: 10.7769 },
    });
    const confirmed = await demoPayments.confirm(created.id, customer.id);
    return { ...created, ...confirmed, id: created.id };
  }

  it('does not match before demo prepayment and confirms exactly once', async () => {
    await makeProvider(106.7009, 10.7769);
    const created = await orders.create(customer.id, {
      incident_type_id: incident.id,
      customer_location: { longitude: 106.7009, latitude: 10.7769 },
    });
    expect(created.status).toBe(OrderStatus.AWAITING_PREPAYMENT);
    expect(await database.getRepository(OrderOffer).countBy({ orderId: created.id })).toBe(0);
    const pending = await database.getRepository(Payment).findOneByOrFail({ orderId: created.id });
    expect(pending.amount).toBe('100000.00');
    expect(pending.status).toBe(PaymentStatus.PENDING);
    const first = await demoPayments.confirm(created.id, customer.id);
    const second = await demoPayments.confirm(created.id, customer.id);
    expect(first.status).toBe(OrderStatus.OFFERED);
    expect(second.status).toBe(OrderStatus.OFFERED);
    expect(await database.getRepository(OrderOffer).countBy({ orderId: created.id })).toBe(1);
    const paid = await database.getRepository(Payment).findOneByOrFail({ orderId: created.id });
    expect(paid.isDemo).toBe(true);
    expect(paid.sepayTransactionId).toBeNull();
  });

  it('cancels an unpaid order without refund', async () => {
    const created = await orders.create(customer.id, {
      incident_type_id: incident.id,
      customer_location: { longitude: 106.7009, latitude: 10.7769 },
    });
    const result = await orders.cancel(created.id, customer.id, 'No longer needed');
    expect(result.status).toBe(OrderStatus.CANCELLED);
    expect(result.refundAmount).toBeNull();
    await expect(demoPayments.confirm(created.id, customer.id)).rejects.toBeInstanceOf(ConflictException);
  });

  it('rejects a demo prepayment record with an amount different from the order snapshot', async () => {
    const created = await orders.create(customer.id, {
      incident_type_id: incident.id,
      customer_location: { longitude: 106.7009, latitude: 10.7769 },
    });
    await database.getRepository(Payment).update({ orderId: created.id }, { amount: '1.00' });
    await expect(demoPayments.confirm(created.id, customer.id)).rejects.toBeInstanceOf(ConflictException);
    expect(await database.getRepository(OrderOffer).countBy({ orderId: created.id })).toBe(0);
  });

  it('requests a full refund before service and admin demo refund is idempotent', async () => {
    const created = await createOrder();
    const cancelled = await orders.cancel(created.id, customer.id, 'No provider found');
    expect(cancelled.status).toBe(OrderStatus.REFUND_PENDING);
    expect(cancelled.refundAmount).toBe('100000.00');
    expect((await admin.pendingRefunds())[0].amount).toBe('100000.00');
    const refunded = await demoPayments.refund(created.id);
    expect(refunded.status).toBe(OrderStatus.REFUNDED);
    expect(await demoPayments.refund(created.id)).toEqual(refunded);
  });

  it('only allows demo confirmation outside production with the feature flag', async () => {
    const created = await orders.create(customer.id, {
      incident_type_id: incident.id,
      customer_location: { longitude: 106.7009, latitude: 10.7769 },
    });
    const disabled = new DemoPaymentsService(database, new ConfigService({ NODE_ENV: 'production', DEMO_MODE: true }), matching);
    await expect(disabled.confirm(created.id, customer.id)).rejects.toThrow('Demo payments are disabled');
    const payment = await database.getRepository(Payment).findOneByOrFail({ orderId: created.id });
    expect(payment.status).toBe(PaymentStatus.PENDING);
  });

  it('confirms concurrent demo payments without creating duplicate offers', async () => {
    await makeProvider(106.7009, 10.7769);
    const created = await orders.create(customer.id, {
      incident_type_id: incident.id,
      customer_location: { longitude: 106.7009, latitude: 10.7769 },
    });
    const results = await Promise.all([
      demoPayments.confirm(created.id, customer.id), demoPayments.confirm(created.id, customer.id),
    ]);
    expect(results.every((result) => result.status === OrderStatus.OFFERED)).toBe(true);
    expect(await database.getRepository(OrderOffer).countBy({ orderId: created.id })).toBe(1);
  });

  it('admin can approve a pending provider only once', async () => {
    const candidate = await makeProvider(106.7, 10.77, { approved: false, online: false });
    await database.getRepository(User).update(candidate.user.id, { status: UserStatus.PENDING_APPROVAL });
    expect((await admin.pendingProviders()).map((provider) => provider.id)).toContain(candidate.provider.id);
    const reviewed = await admin.reviewProvider(candidate.provider.id, ApprovalStatus.APPROVED);
    expect(reviewed.approvalStatus).toBe(ApprovalStatus.APPROVED);
    expect((await database.getRepository(User).findOneByOrFail({ id: candidate.user.id })).status).toBe(UserStatus.ACTIVE);
    expect((await providersService.updateStatus(candidate.user.id, true)).isOnline).toBe(true);
    await expect(admin.reviewProvider(candidate.provider.id, ApprovalStatus.REJECTED)).rejects.toBeInstanceOf(ConflictException);
    const rejected = await makeProvider(106.7, 10.77, { approved: false, online: false });
    await database.getRepository(User).update(rejected.user.id, { status: UserStatus.PENDING_APPROVAL });
    await admin.reviewProvider(rejected.provider.id, ApprovalStatus.REJECTED);
    expect((await database.getRepository(User).findOneByOrFail({ id: rejected.user.id })).status).toBe(UserStatus.SUSPENDED);
  });

  it('restricts chat and location to active order participants', async () => {
    const assigned = await makeProvider(106.7009, 10.7769);
    const outsider = await makeProvider(106.701, 10.777);
    const created = await createOrder();
    const offer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: created.id });
    await orders.accept(created.id, offer.id, assigned.user.id);
    expect((await orders.listMine(customer.id, UserRole.CUSTOMER))[0].id).toBe(created.id);
    expect((await orders.listMine(assigned.user.id, UserRole.PROVIDER))[0].id).toBe(created.id);
    expect((await admin.recentOrders())[0].id).toBe(created.id);
    const sent = await messages.create(created.id, customer.id, 'Please come soon');
    expect((await messages.list(created.id, assigned.user.id))[0].content).toBe('Please come soon');
    expect(messageCreated).toHaveBeenCalledWith(created.id, expect.objectContaining({ id: sent.id }));
    await expect(messages.list(created.id, outsider.user.id)).rejects.toBeInstanceOf(NotFoundException);
    const providerService = new ProvidersService(
      database.getRepository(Provider), database.getRepository(OrderOffer), database.getRepository(User),
      new ConfigService({ PROVIDER_LOCATION_MAX_AGE_SECONDS: 120 }), database.getRepository(Order),
      { providerLocation } as unknown as RealtimeGateway,
    );
    await providerService.updateOrderLocation(assigned.user.id, created.id, { latitude: 10.778, longitude: 106.702 });
    expect(providerLocation).toHaveBeenCalledWith(created.id, assigned.provider.id, 10.778, 106.702, expect.any(Date));
    await expect(providerService.updateOrderLocation(outsider.user.id, created.id, { latitude: 10.778, longitude: 106.702 }))
      .rejects.toBeInstanceOf(NotFoundException);
    await orders.cancel(created.id, customer.id, 'Cancel before repair');
    await expect(messages.create(created.id, assigned.user.id, 'Still coming?')).rejects.toBeInstanceOf(NotFoundException);
    expect((await messages.list(created.id, customer.id))[0].content).toBe('Please come soon');
  });

  it('requires arrival and a customer start token, then settles the demo order once', async () => {
    const assigned = await makeProvider(106.7009, 10.7769);
    const outsider = await makeProvider(106.701, 10.777);
    const created = await createOrder();
    const offer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: created.id });
    await orders.accept(created.id, offer.id, assigned.user.id);
    await expect(orders.startToken(created.id, customer.id)).rejects.toBeInstanceOf(ConflictException);
    await expect(orders.arrive(created.id, outsider.user.id)).rejects.toBeInstanceOf(NotFoundException);
    expect((await orders.arrive(created.id, assigned.user.id)).status).toBe(OrderStatus.ARRIVED);
    const token = (await orders.startToken(created.id, customer.id)).token;
    await expect(orders.start(created.id, outsider.user.id, token)).rejects.toBeInstanceOf(NotFoundException);
    await expect(orders.start(created.id, assigned.user.id, token.slice(0, -1) + (token.endsWith('0') ? '1' : '0'))).rejects.toThrow();
    expect((await orders.start(created.id, assigned.user.id, token)).status).toBe(OrderStatus.IN_PROGRESS);
    await expect(orders.cancel(created.id, customer.id, 'Changed my mind')).rejects.toBeInstanceOf(ConflictException);
    expect((await orders.complete(created.id, assigned.user.id)).finalPrice).toBe('100000.00');
    expect((await database.getRepository(Wallet).findOneByOrFail({ providerId: assigned.provider.id })).balance).toBe('100000.00');
    expect(await database.getRepository(WalletTransaction).countBy({ orderId: created.id })).toBe(1);
    const wallet = await new WalletsController(database).mine({ sub: assigned.user.id, role: UserRole.PROVIDER });
    expect(wallet.balance).toBe('100000.00');
    expect(wallet.demoOnly).toBe(true);
    const reviews = new ReviewsService(database);
    expect((await reviews.create(created.id, customer.id, { rating: 5, comment: 'Helpful' })).revieweeId).toBe(assigned.user.id);
    expect((await reviews.create(created.id, assigned.user.id, { rating: 4 })).revieweeId).toBe(customer.id);
    expect(await reviews.list(created.id, customer.id)).toHaveLength(2);
    await expect(reviews.create(created.id, customer.id, { rating: 1 })).rejects.toBeInstanceOf(ConflictException);
    await expect(reviews.list(created.id, outsider.user.id)).rejects.toBeInstanceOf(NotFoundException);
    await expect(orders.complete(created.id, assigned.user.id)).rejects.toBeInstanceOf(ConflictException);
  });

  it('allows only one concurrent demo completion and one wallet credit', async () => {
    const assigned = await makeProvider(106.7009, 10.7769);
    const created = await createOrder();
    const offer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: created.id });
    await orders.accept(created.id, offer.id, assigned.user.id);
    await orders.arrive(created.id, assigned.user.id);
    const token = (await orders.startToken(created.id, customer.id)).token;
    await orders.start(created.id, assigned.user.id, token);
    const results = await Promise.allSettled([
      orders.complete(created.id, assigned.user.id), orders.complete(created.id, assigned.user.id),
    ]);
    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(await database.getRepository(WalletTransaction).countBy({ orderId: created.id })).toBe(1);
    expect((await database.getRepository(Wallet).findOneByOrFail({ providerId: assigned.provider.id })).balance).toBe('100000.00');
  });

  it('only joins a socket to a room after JWT and order participation checks', async () => {
    const assigned = await makeProvider(106.7009, 10.7769);
    const stranger = await makeUser(UserRole.CUSTOMER);
    const created = await createOrder();
    const offer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: created.id });
    await orders.accept(created.id, offer.id, assigned.user.id);
    const jwt = new JwtService({ secret: 'test-only-socket-secret-with-more-than-32-characters' });
    const gateway = new RealtimeGateway(jwt, database);
    const participant = {
      handshake: { auth: { token: await jwt.signAsync({ sub: assigned.user.id, role: UserRole.PROVIDER, ver: 0 }), orderId: created.id } },
      data: {}, join: jest.fn(), disconnect: jest.fn(),
    } as unknown as Socket;
    await gateway.handleConnection(participant);
    expect(participant.join).toHaveBeenCalledWith(`provider:${assigned.provider.id}`);
    expect(participant.join).toHaveBeenCalledWith(`order:${created.id}`);
    expect(participant.disconnect).not.toHaveBeenCalled();
    const intruder = {
      handshake: { auth: { token: await jwt.signAsync({ sub: stranger.id, role: UserRole.CUSTOMER, ver: 0 }), orderId: created.id } },
      data: {}, join: jest.fn(), disconnect: jest.fn(),
    } as unknown as Socket;
    await gateway.handleConnection(intruder);
    expect(intruder.join).not.toHaveBeenCalledWith(`order:${created.id}`);
    expect(intruder.disconnect).toHaveBeenCalled();
  });

  it('creates an order and snapshots the current price', async () => {
    await makeProvider(106.7009, 10.7769);
    const result = await createOrder();
    expect(result.status).toBe(OrderStatus.OFFERED);
    expect(result.matched).toBe(true);
    expect(result.estimatedPrice).toBe('100000.00');
    incident.basePrice = '200000.00';
    await database.getRepository(IncidentType).save(incident);
    const stored = await database.getRepository(Order).findOneByOrFail({ id: result.id });
    expect(stored.estimatedPrice).toBe('100000.00');
  });

  it('persists a severe-weather price snapshot and matching payment amount', async () => {
    const weatherConfig = new ConfigService({
      MATCH_RADIUS_KM: 10,
      OFFER_TTL_SECONDS: 15,
      PROVIDER_LOCATION_MAX_AGE_SECONDS: 120,
      WEATHER_PRICING_ENABLED: true,
      WEATHER_REQUEST_TIMEOUT_MS: 1000,
      WEATHER_CACHE_TTL_SECONDS: 300,
      NODE_ENV: 'test',
      DEMO_MODE: true,
      JWT_SECRET: 'test-only-order-start-secret-longer-than-32-characters',
    });
    const weatherFetcher: WeatherFetcher = async () => ({
      ok: true,
      json: async () => ({
        current: {
          time: '2026-10-06T08:00', weather_code: 95, precipitation: 8, rain: 8,
          wind_speed_10m: 45, wind_gusts_10m: 65,
        },
      }),
    });
    const weatherOrders = new OrdersService(
      database,
      matching,
      weatherConfig,
      new OrderPricingService(new WeatherService(weatherConfig, weatherFetcher)),
    );
    const created = await weatherOrders.create(customer.id, {
      incident_type_id: incident.id,
      customer_location: { longitude: 106.7009, latitude: 10.7769 },
    });
    expect(created).toMatchObject({
      estimatedPrice: '120000.00',
      pricing: {
        basePrice: '100000.00', weatherSurcharge: '20000.00', weatherMultiplier: '1.2000',
        weatherCategory: 'SEVERE', weatherSource: 'OPEN_METEO',
      },
    });
    const payment = await database.getRepository(Payment).findOneByOrFail({ orderId: created.id });
    expect(payment.amount).toBe('120000.00');
  });

  it('offers to the nearest available provider and excludes unavailable providers', async () => {
    const nearest = await makeProvider(106.7009, 10.7769, { approved: false });
    await makeProvider(106.701, 10.777, { online: false });
    await makeProvider(106.7011, 10.7771, { fresh: false });
    await makeProvider(106.7012, 10.7772, { active: false });
    const busy = await makeProvider(106.7013, 10.7773);
    await database.getRepository(Order).save(
      database.getRepository(Order).create({
        code: 'BUSY-TEST',
        customerId: customer.id,
        providerId: busy.provider.id,
        incidentTypeId: incident.id,
        status: OrderStatus.ACCEPTED,
        customerLocation: { type: 'Point', coordinates: [106.7009, 10.7769] },
        basePrice: '100000.00',
        estimatedPrice: '100000.00',
      }),
    );
    const selected = await makeProvider(106.702, 10.778);
    await makeProvider(106.71, 10.79);
    const result = await createOrder();
    const offer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: result.id });
    expect(offer.providerId).toBe(selected.provider.id);
    expect(offer.providerId).not.toBe(nearest.provider.id);
  });

  it('keeps the order pending when no provider exists and allows retry', async () => {
    const result = await createOrder();
    expect(result.status).toBe(OrderStatus.PENDING_MATCH);
    expect(result.matched).toBe(false);
    await makeProvider(106.7009, 10.7769);
    const retried = await orders.retry(result.id, customer.id);
    expect(retried.status).toBe(OrderStatus.OFFERED);
  });

  it('rejects inactive incident types and hides orders from unrelated users', async () => {
    incident.isActive = false;
    await database.getRepository(IncidentType).save(incident);
    await expect(createOrder()).rejects.toBeInstanceOf(NotFoundException);
    incident.isActive = true;
    await database.getRepository(IncidentType).save(incident);
    const result = await createOrder();
    const stranger = await makeUser(UserRole.CUSTOMER);
    await expect(orders.getById(result.id, stranger.id)).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rejects an offer and immediately picks the next provider', async () => {
    const first = await makeProvider(106.7009, 10.7769);
    const second = await makeProvider(106.7019, 10.7779);
    const result = await createOrder();
    const firstOffer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: result.id });
    expect(firstOffer.providerId).toBe(first.provider.id);
    const rejected = await orders.reject(result.id, firstOffer.id, first.user.id);
    expect(rejected.status).toBe(OrderStatus.OFFERED);
    const next = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: result.id, status: OfferStatus.PENDING });
    expect(next.providerId).toBe(second.provider.id);
  });

  it('returns to pending matching after the only provider rejects', async () => {
    const only = await makeProvider(106.7009, 10.7769);
    const result = await createOrder();
    const offer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: result.id });
    const rejected = await orders.reject(result.id, offer.id, only.user.id);
    expect(rejected.status).toBe(OrderStatus.PENDING_MATCH);
    expect(rejected.matched).toBe(false);
  });

  it('expires an offer and moves to the next provider', async () => {
    await makeProvider(106.7009, 10.7769);
    const second = await makeProvider(106.7019, 10.7779);
    const result = await createOrder();
    const firstOffer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: result.id });
    firstOffer.expiresAt = new Date(Date.now() - 1000);
    await database.getRepository(OrderOffer).save(firstOffer);
    await new OfferExpiryService(database, matching).expirePendingOffers();
    const expired = await database.getRepository(OrderOffer).findOneByOrFail({ id: firstOffer.id });
    const next = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: result.id, status: OfferStatus.PENDING });
    expect(expired.status).toBe(OfferStatus.EXPIRED);
    expect(next.providerId).toBe(second.provider.id);
  });

  it('allows only one of two simultaneous accept requests', async () => {
    const selected = await makeProvider(106.7009, 10.7769);
    const result = await createOrder();
    const offer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: result.id });
    const outcomes = await Promise.allSettled([
      orders.accept(result.id, offer.id, selected.user.id),
      orders.accept(result.id, offer.id, selected.user.id),
    ]);
    expect(outcomes.filter((outcome) => outcome.status === 'fulfilled')).toHaveLength(1);
    expect(outcomes.filter((outcome) => outcome.status === 'rejected')).toHaveLength(1);
    const stored = await database.getRepository(Order).findOneByOrFail({ id: result.id });
    expect(stored.status).toBe(OrderStatus.ACCEPTED);
    expect(stored.providerId).toBe(selected.provider.id);
  });

  it('does not offer the same provider to two simultaneous orders', async () => {
    await makeProvider(106.7009, 10.7769);
    const results = await Promise.all([createOrder(), createOrder()]);
    expect(results.filter((result) => result.matched)).toHaveLength(1);
    expect(results.filter((result) => !result.matched)).toHaveLength(1);
  });

  it('requires the correct provider and rejects acceptance after expiry', async () => {
    const selected = await makeProvider(106.7009, 10.7769);
    const other = await makeProvider(106.702, 10.778);
    const result = await createOrder();
    const offer = await database.getRepository(OrderOffer).findOneByOrFail({ orderId: result.id });
    await expect(orders.accept(result.id, offer.id, other.user.id)).rejects.toThrow();
    offer.expiresAt = new Date(Date.now() - 1000);
    await database.getRepository(OrderOffer).save(offer);
    await expect(orders.accept(result.id, offer.id, selected.user.id)).rejects.toBeInstanceOf(ConflictException);
  });

  it('returns only the current provider pending offer and requires fresh GPS to go online', async () => {
    const selected = await makeProvider(106.7009, 10.7769);
    const other = await makeProvider(106.702, 10.778);
    const result = await createOrder();
    const offers = await providersService.pendingOffers(selected.user.id);
    expect(offers).toHaveLength(1);
    expect(offers[0].orderId).toBe(result.id);
    expect(await providersService.pendingOffers(other.user.id)).toHaveLength(0);
    await providersService.updateStatus(selected.user.id, false);
    await database.getRepository(Provider).update(selected.provider.id, { lastSeenAt: new Date(Date.now() - 300_000) });
    await expect(providersService.updateStatus(selected.user.id, true)).rejects.toThrow();
    await providersService.updateLocation(selected.user.id, { latitude: 10.7769, longitude: 106.7009 });
    expect((await providersService.updateStatus(selected.user.id, true)).isOnline).toBe(true);
  });

  it('resets a password once and increments the JWT auth version', async () => {
    await passwordRecovery.forgot(customer.email!);
    expect(deliveredCode).toMatch(/^\d{6}$/);
    await expect(passwordRecovery.reset(customer.email!, '999999', 'NewPassword123!'))
      .rejects.toBeInstanceOf(BadRequestException);
    await passwordRecovery.reset(customer.email!, deliveredCode!, 'NewPassword123!');
    const updated = await database.getRepository(User).createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('user.id = :id', { id: customer.id })
      .getOneOrFail();
    expect(await argon2.verify(updated.passwordHash, 'NewPassword123!')).toBe(true);
    expect(updated.authVersion).toBe(1);
    const users = new UsersService(database.getRepository(User), database);
    const strategy = new JwtStrategy(
      new ConfigService({ JWT_SECRET: 'test-only-order-start-secret-longer-than-32-characters' }), users,
    );
    await expect(strategy.validate({ sub: customer.id, role: UserRole.CUSTOMER, ver: 0 }))
      .rejects.toBeInstanceOf(UnauthorizedException);
    await expect(strategy.validate({ sub: customer.id, role: UserRole.CUSTOMER, ver: 1 }))
      .resolves.toMatchObject({ sub: customer.id, ver: 1 });
    await expect(passwordRecovery.reset(customer.email!, deliveredCode!, 'AnotherPassword123!'))
      .rejects.toBeInstanceOf(BadRequestException);
  });

  it('temporarily locks an account after five failed logins', async () => {
    const users = new UsersService(database.getRepository(User), database);
    for (let attempt = 0; attempt < 5; attempt += 1) await users.recordFailedLogin(customer.id);
    const locked = await database.getRepository(User).findOneByOrFail({ id: customer.id });
    expect(locked.failedLoginAttempts).toBe(0);
    expect(locked.lockedUntil!.getTime()).toBeGreaterThan(Date.now());
  });

  it('creates a pending provider profile together with registration', async () => {
    const users = new UsersService(database.getRepository(User), database);
    const user = await users.create({
      name: 'New provider',
      email: `${randomUUID()}@motocare.test`,
      phone: null,
      passwordHash: 'test-only-hash',
      role: UserRole.PROVIDER,
      status: UserStatus.PENDING_APPROVAL,
    });
    const provider = await database.getRepository(Provider).findOneByOrFail({ userId: user.id });
    expect(provider.approvalStatus).toBe(ApprovalStatus.PENDING);
    expect(provider.isOnline).toBe(false);
  });
});
