import { ConflictException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { randomUUID } from 'node:crypto';
import { DataSource } from 'typeorm';
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
import { OrdersService } from '../src/orders/orders.service';
import { Provider } from '../src/providers/provider.entity';
import { ProvidersService } from '../src/providers/providers.service';
import { User } from '../src/users/user.entity';
import { UsersService } from '../src/users/users.service';

const testDatabase = process.env.TEST_DATABASE_NAME;
if (!testDatabase || !/^motocare_[a-z0-9_]*test$/.test(testDatabase)) {
  throw new Error('Set TEST_DATABASE_NAME to a dedicated MotoCare test database');
}

describe('Orders and matching on PostGIS', () => {
  let database: DataSource;
  let orders: OrdersService;
  let matching: MatchingService;
  let providersService: ProvidersService;
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
      entities: [User, Provider, IncidentType, Order, OrderOffer],
      synchronize: false,
      logging: false,
    });
    await database.initialize();
    const config = new ConfigService({
      MATCH_RADIUS_KM: 10,
      OFFER_TTL_SECONDS: 15,
      PROVIDER_LOCATION_MAX_AGE_SECONDS: 120,
    });
    matching = new MatchingService(database, config);
    orders = new OrdersService(database, matching);
    providersService = new ProvidersService(
      database.getRepository(Provider),
      database.getRepository(OrderOffer),
      database.getRepository(User),
      config,
    );
  });

  beforeEach(async () => {
    await database.query('TRUNCATE TABLE users, incident_types RESTART IDENTITY CASCADE');
    customer = await makeUser(UserRole.CUSTOMER);
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
    return orders.create(customer.id, {
      incident_type_id: incident.id,
      customer_location: { longitude: 106.7009, latitude: 10.7769 },
    });
  }

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
