import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ScheduleModule } from '@nestjs/schedule';
import { Test } from '@nestjs/testing';
import { TypeOrmModule } from '@nestjs/typeorm';
import { createHmac } from 'node:crypto';
import { rm } from 'node:fs/promises';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AdminModule } from '../src/admin/admin.module';
import { JwtStrategy } from '../src/auth/jwt.strategy';
import { JwtAuthGuard } from '../src/common/guards/jwt-auth.guard';
import { RolesGuard } from '../src/common/guards/roles.guard';
import { UserRole } from '../src/common/enums/user-role.enum';
import { UserStatus } from '../src/common/enums/user-status.enum';
import { HealthModule } from '../src/health/health.module';
import { IncidentType } from '../src/incident-types/incident-type.entity';
import { IncidentTypesModule } from '../src/incident-types/incident-types.module';
import { OrdersModule } from '../src/orders/orders.module';
import { PaymentsModule } from '../src/payments/payments.module';
import { Provider } from '../src/providers/provider.entity';
import { ProvidersModule } from '../src/providers/providers.module';
import { ReviewsModule } from '../src/reviews/reviews.module';
import { User } from '../src/users/user.entity';
import { UsersModule } from '../src/users/users.module';
import { VehiclesModule } from '../src/vehicles/vehicles.module';
import { ServiceLocationsModule } from '../src/service-locations/service-locations.module';
import { ServiceLocation } from '../src/service-locations/service-location.entity';
import { ServiceLocationSource, ServiceLocationType } from '../src/service-locations/service-location-type.enum';
import { SkillVerificationStatus } from '../src/providers/skill-verification-status.enum';
import { Wallet } from '../src/payments/wallet.entity';
import { WalletTransaction } from '../src/payments/wallet-transaction.entity';
import { WalletTransactionType } from '../src/common/enums/wallet-transaction-type.enum';
import { Review } from '../src/reviews/review.entity';
import { Order } from '../src/orders/order.entity';
import { OrderStatus } from '../src/common/enums/order-status.enum';
import { Notification } from '../src/notifications/notification.entity';
import { NotificationType } from '../src/notifications/notification-type.enum';
import { NotificationsService } from '../src/notifications/notifications.service';
import { NotificationDeliveryService } from '../src/notifications/notification-delivery.service';
import { NotificationDelivery } from '../src/notifications/notification-delivery.entity';
import { NotificationDeliveryStatus } from '../src/notifications/notification-delivery-status.enum';
import { PushGateway, PushMessage } from '../src/notifications/push-gateway.port';
import { DevicePlatform } from '../src/notifications/device-platform.enum';

const testDatabase = process.env.TEST_DATABASE_NAME;
if (!testDatabase || !/^motocare_[a-z0-9_]*test$/.test(testDatabase)) {
  throw new Error('Set TEST_DATABASE_NAME to a dedicated MotoCare test database');
}

type Session = {
  token: string;
  userId: number;
};

describe('Sandbox demo flow over HTTP', () => {
  let app: INestApplication;
  let database: DataSource;
  let jwt: JwtService;
  let incident: IncidentType;
  let admin: Session;
  const password = 'HttpTestOnly123!';
  const png = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    'base64',
  );

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ isGlobal: true, ignoreEnvFile: true }),
        ScheduleModule.forRoot(),
        TypeOrmModule.forRoot({
          type: 'postgres',
          host: process.env.DATABASE_HOST,
          port: Number(process.env.DATABASE_PORT ?? 5432),
          username: process.env.DATABASE_USER,
          password: process.env.DATABASE_PASSWORD,
          database: testDatabase,
          autoLoadEntities: true,
          synchronize: false,
        }),
        PassportModule.register({ defaultStrategy: 'jwt' }),
        JwtModule.register({ secret: process.env.JWT_SECRET, signOptions: { expiresIn: '1d' } }),
        UsersModule,
        VehiclesModule,
        HealthModule,
        IncidentTypesModule,
        OrdersModule,
        PaymentsModule,
        ProvidersModule,
        ServiceLocationsModule,
        ReviewsModule,
        AdminModule,
      ],
      providers: [
        JwtStrategy,
        JwtAuthGuard,
        RolesGuard,
        { provide: APP_GUARD, useExisting: JwtAuthGuard },
        { provide: APP_GUARD, useExisting: RolesGuard },
      ],
    }).compile();
    app = moduleRef.createNestApplication({ rawBody: true });
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    database = app.get(DataSource);
    jwt = app.get(JwtService);
  });

  beforeEach(async () => {
    await database.query('TRUNCATE TABLE users, incident_types, skills, service_locations RESTART IDENTITY CASCADE');
    incident = await database.getRepository(IncidentType).save(
      database.getRepository(IncidentType).create({
        code: 'FLAT_TIRE',
        name: 'Xẹp lốp',
        basePrice: '100000.00',
        isActive: true,
      }),
    );
    admin = await createActor('Demo Admin', 'admin.http-test@motocare.test', UserRole.ADMIN, UserStatus.ACTIVE);
  });

  afterAll(async () => {
    await app?.close();
    if (process.env.CHAT_UPLOAD_DIR) await rm(process.env.CHAT_UPLOAD_DIR, { recursive: true, force: true });
  });

  async function createActor(name: string, email: string, role: UserRole, status: UserStatus): Promise<Session> {
    const user = await database.getRepository(User).save(
      database.getRepository(User).create({ name, email, phone: null, passwordHash: password, role, status }),
    );
    if (role === UserRole.PROVIDER) {
      await database.getRepository(Provider).save(database.getRepository(Provider).create({ userId: user.id }));
    }
    return { token: await jwt.signAsync({ sub: user.id, role, ver: user.authVersion }), userId: user.id };
  }

  async function prepareActors() {
    const customer = await createActor(
      'HTTP Customer', 'customer.http-test@motocare.test', UserRole.CUSTOMER, UserStatus.ACTIVE,
    );
    const provider = await createActor(
      'HTTP Provider', 'provider.http-test@motocare.test', UserRole.PROVIDER, UserStatus.PENDING_APPROVAL,
    );

    const pending = await request(app.getHttpServer())
      .get('/admin/providers/pending')
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200);
    const providerProfile = (pending.body as Array<{ id: number; userId: number }>).find(
      (candidate) => candidate.userId === provider.userId,
    );
    expect(providerProfile).toBeDefined();

    await request(app.getHttpServer())
      .patch(`/admin/providers/${providerProfile!.id}/approval`)
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ status: 'APPROVED' })
      .expect(200);
    await request(app.getHttpServer())
      .patch('/providers/me/location')
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ latitude: 10.7769, longitude: 106.7009 })
      .expect(200);
    await request(app.getHttpServer())
      .patch('/providers/me/status')
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ isOnline: true })
      .expect(200);

    return { admin, customer, provider };
  }

  async function createAndMatch(customerToken: string) {
    const created = await request(app.getHttpServer())
      .post('/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        incident_type_id: incident.id,
        customer_location: { latitude: 10.7769, longitude: 106.7009 },
      })
      .expect(201);
    expect(created.body).toMatchObject({
      status: 'AWAITING_PREPAYMENT', estimatedPrice: '100000.00', matched: false,
      pricing: { basePrice: '100000.00', weatherSurcharge: '0.00', weatherMultiplier: '1.0000', weatherCategory: 'DISABLED' },
    });

    const confirmed = await request(app.getHttpServer())
      .post(`/payments/demo/orders/${created.body.id}/confirm`)
      .set('Authorization', `Bearer ${customerToken}`)
      .expect(200);
    expect(confirmed.body).toMatchObject({ status: 'OFFERED', matched: true });
    return created.body.id as number;
  }

  function analyticsQuery(): string {
    const from = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const to = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
    return `from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`;
  }

  function signedSepayPayload(payload: object) {
    const rawBody = JSON.stringify(payload);
    const timestamp = String(Math.floor(Date.now() / 1000));
    const signature = `sha256=${createHmac('sha256', process.env.SEPAY_WEBHOOK_SECRET!)
      .update(timestamp)
      .update('.')
      .update(rawBody)
      .digest('hex')}`;
    return { rawBody, timestamp, signature };
  }

  it('manages Customer vehicles, snapshots one into the order and protects tap-to-call contact', async () => {
    const { customer, provider } = await prepareActors();
    await request(app.getHttpServer())
      .patch('/users/me')
      .set('Authorization', `Bearer ${customer.token}`)
      .send({
        name: 'HTTP Customer Updated',
        phone: '0901234567',
        emergencyContactName: 'Relative',
        emergencyContactPhone: '0912345678',
        medicalNote: 'Allergic to medicine A',
        homeAddress: 'District 1, HCMC',
        workAddress: 'District 3, HCMC',
      })
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({
        name: 'HTTP Customer Updated',
        phone: '0901234567',
        emergencyContactName: 'Relative',
        emergencyContactPhone: '0912345678',
        medicalNote: 'Allergic to medicine A',
        homeAddress: 'District 1, HCMC',
        workAddress: 'District 3, HCMC',
      }));
    await request(app.getHttpServer())
      .patch('/users/me')
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ phone: '0907654321' })
      .expect(200);
    await request(app.getHttpServer())
      .patch('/users/me')
      .set('Authorization', `Bearer ${customer.token}`)
      .send({ role: 'ADMIN' })
      .expect(400);

    const vehicle = await request(app.getHttpServer())
      .post('/users/me/vehicles')
      .set('Authorization', `Bearer ${customer.token}`)
      .send({
        type: 'MOTORBIKE',
        brand: 'Honda',
        model: 'Wave Alpha',
        licensePlate: '59a1-123.45',
        color: 'Black',
      })
      .expect(201);
    expect(vehicle.body).toMatchObject({ licensePlate: '59A1-123.45', isDefault: true });
    await request(app.getHttpServer())
      .post('/users/me/vehicles')
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ type: 'MOTORBIKE', brand: 'Honda', model: 'Wave', licensePlate: '59A1-999.99' })
      .expect(403);

    const created = await request(app.getHttpServer())
      .post('/orders')
      .set('Authorization', `Bearer ${customer.token}`)
      .send({
        incident_type_id: incident.id,
        vehicle_id: vehicle.body.id,
        customer_location: { latitude: 10.7769, longitude: 106.7009 },
      })
      .expect(201);
    expect(created.body.vehicle).toMatchObject({
      sourceVehicleId: vehicle.body.id,
      type: 'MOTORBIKE',
      licensePlate: '59A1-123.45',
    });
    await request(app.getHttpServer())
      .post(`/payments/demo/orders/${created.body.id}/confirm`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200);
    await request(app.getHttpServer())
      .get(`/orders/${created.body.id}/participant-contact`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(404);
    const offers = await request(app.getHttpServer())
      .get('/providers/me/offers/pending')
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200);
    await request(app.getHttpServer())
      .post(`/orders/${created.body.id}/offers/${offers.body[0].id}/accept`)
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200);
    await request(app.getHttpServer())
      .get(`/orders/${created.body.id}/participant-contact`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({ role: 'PROVIDER', phone: '0907654321' }));
    await request(app.getHttpServer())
      .get(`/orders/${created.body.id}/participant-contact`)
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({ role: 'CUSTOMER', phone: '0901234567' }));

    await request(app.getHttpServer())
      .delete(`/users/me/vehicles/${vehicle.body.id}`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200);
    await request(app.getHttpServer())
      .get(`/orders/${created.body.id}`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body.vehicle).toMatchObject({ sourceVehicleId: null, licensePlate: '59A1-123.45' }));
    await request(app.getHttpServer())
      .post(`/orders/${created.body.id}/cancel`)
      .set('Authorization', `Bearer ${customer.token}`)
      .send({ reason: 'Cancel before repair' })
      .expect(200);
    await request(app.getHttpServer())
      .get(`/orders/${created.body.id}/participant-contact`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(409);
  });

  it('confirms an exact SePay Test mode prepayment once and starts matching', async () => {
    const { customer } = await prepareActors();
    const created = await request(app.getHttpServer())
      .post('/orders')
      .set('Authorization', `Bearer ${customer.token}`)
      .send({
        incident_type_id: incident.id,
        customer_location: { latitude: 10.7769, longitude: 106.7009 },
      })
      .expect(201);
    const instructions = await request(app.getHttpServer())
      .get(`/payments/orders/${created.body.id}/instructions`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200);
    expect(instructions.body).toMatchObject({
      provider: 'SEPAY',
      mode: 'test',
      simulationOnly: true,
      amount: '100000.00',
      bank: 'MBBank',
      accountNumber: 'SBSEPAYX9KA2B7MN4QR',
    });

    const payload = {
      id: 900001,
      gateway: 'MBBank',
      transactionDate: '2026-10-08 10:30:00',
      accountNumber: 'TEST-ACCOUNT-001',
      subAccount: 'SBSEPAYX9KA2B7MN4QR',
      code: instructions.body.paymentCode,
      content: `${instructions.body.paymentCode} thanh toan`,
      transferType: 'in',
      description: 'TEST MODE transaction',
      transferAmount: 100000,
      accumulated: 500000,
      referenceCode: 'SBTEST900001',
    };
    const signed = signedSepayPayload(payload);
    const sendWebhook = () =>
      request(app.getHttpServer())
        .post('/payments/webhooks/sepay')
        .set('Content-Type', 'application/json')
        .set('X-SePay-Timestamp', signed.timestamp)
        .set('X-SePay-Signature', signed.signature)
        .send(signed.rawBody);

    await request(app.getHttpServer())
      .post('/payments/webhooks/sepay')
      .set('Content-Type', 'application/json')
      .set('X-SePay-Timestamp', signed.timestamp)
      .set('X-SePay-Signature', `sha256=${'0'.repeat(64)}`)
      .send(signed.rawBody)
      .expect(401);
    await sendWebhook().expect(200, { success: true });
    await sendWebhook().expect(200, { success: true });
    await request(app.getHttpServer())
      .get(`/orders/${created.body.id}`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) =>
        expect(body).toMatchObject({
          status: 'OFFERED',
          payment: { status: 'PAID', isDemo: false },
        }),
      );

    const [audit] = (await database.query(
      'SELECT outcome, external_transaction_id FROM sepay_webhook_events WHERE external_transaction_id = $1',
      [String(payload.id)],
    )) as Array<{ outcome: string; external_transaction_id: string }>;
    expect(audit).toEqual({ outcome: 'APPLIED', external_transaction_id: String(payload.id) });

    const secondOrder = await request(app.getHttpServer())
      .post('/orders')
      .set('Authorization', `Bearer ${customer.token}`)
      .send({
        incident_type_id: incident.id,
        customer_location: { latitude: 10.7769, longitude: 106.7009 },
      })
      .expect(201);
    const secondInstructions = await request(app.getHttpServer())
      .get(`/payments/orders/${secondOrder.body.id}/instructions`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200);
    const wrongAmount = signedSepayPayload({
      ...payload,
      id: 900002,
      code: secondInstructions.body.paymentCode,
      content: `${secondInstructions.body.paymentCode} wrong amount`,
      transferAmount: 99999,
      referenceCode: 'SBTEST900002',
    });
    await request(app.getHttpServer())
      .post('/payments/webhooks/sepay')
      .set('Content-Type', 'application/json')
      .set('X-SePay-Timestamp', wrongAmount.timestamp)
      .set('X-SePay-Signature', wrongAmount.signature)
      .send(wrongAmount.rawBody)
      .expect(200, { success: true });
    await request(app.getHttpServer())
      .get(`/orders/${secondOrder.body.id}`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) =>
        expect(body).toMatchObject({
          status: 'AWAITING_PREPAYMENT',
          payment: { status: 'PENDING' },
        }),
      );
    const [mismatch] = (await database.query(
      'SELECT outcome FROM sepay_webhook_events WHERE external_transaction_id = $1',
      ['900002'],
    )) as Array<{ outcome: string }>;
    expect(mismatch.outcome).toBe('AMOUNT_MISMATCH');
  });

  it('completes the customer, provider and admin sandbox lifecycle', async () => {
    const { customer, provider } = await prepareActors();

    await request(app.getHttpServer()).get('/health/ready').expect(200, { status: 'ok', database: 'ok' });
    const catalog = await request(app.getHttpServer())
      .get('/incident-types')
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200);
    expect(catalog.body).toEqual([
      expect.objectContaining({ id: incident.id, code: 'FLAT_TIRE', basePrice: '100000.00' }),
    ]);

    const orderId = await createAndMatch(customer.token);
    const offers = await request(app.getHttpServer())
      .get('/providers/me/offers/pending')
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200);
    expect(offers.body).toHaveLength(1);
    const offerId = offers.body[0].id as number;

    await request(app.getHttpServer())
      .post(`/orders/${orderId}/offers/${offerId}/accept`)
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200)
      .expect(({ body }) => expect(body.status).toBe('ACCEPTED'));
    await request(app.getHttpServer())
      .patch(`/providers/me/orders/${orderId}/location`)
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ latitude: 10.7775, longitude: 106.7015 })
      .expect(200);
    await request(app.getHttpServer())
      .post(`/orders/${orderId}/messages`)
      .set('Authorization', `Bearer ${customer.token}`)
      .send({ content: 'Anh đến cổng giúp em nhé.' })
      .expect(201);
    const messages = await request(app.getHttpServer())
      .get(`/orders/${orderId}/messages`)
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200);
    expect(messages.body[0].content).toBe('Anh đến cổng giúp em nhé.');
    const imageMessage = await request(app.getHttpServer())
      .post(`/orders/${orderId}/messages`)
      .set('Authorization', `Bearer ${customer.token}`)
      .field('content', 'Ảnh vị trí của em')
      .attach('image', png, { filename: 'location.png', contentType: 'image/png' })
      .expect(201);
    expect(imageMessage.body).toMatchObject({
      content: 'Ảnh vị trí của em', image: { mimeType: 'image/png', sizeBytes: png.length },
    });
    await request(app.getHttpServer())
      .get(imageMessage.body.image.url)
      .set('Authorization', `Bearer ${provider.token}`)
      .expect('Content-Type', /image\/png/)
      .expect(200);
    const outsider = await createActor(
      'HTTP Outsider', 'outsider.http-test@motocare.test', UserRole.CUSTOMER, UserStatus.ACTIVE,
    );
    await request(app.getHttpServer())
      .get(imageMessage.body.image.url)
      .set('Authorization', `Bearer ${outsider.token}`)
      .expect(404);

    await request(app.getHttpServer())
      .post(`/orders/${orderId}/arrive`)
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200)
      .expect(({ body }) => expect(body.status).toBe('ARRIVED'));
    const startToken = await request(app.getHttpServer())
      .get(`/orders/${orderId}/start-token`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200);
    await request(app.getHttpServer())
      .post(`/orders/${orderId}/start`)
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ token: startToken.body.token })
      .expect(200)
      .expect(({ body }) => expect(body.status).toBe('IN_PROGRESS'));
    const priceProposal = await request(app.getHttpServer())
      .post(`/orders/${orderId}/price-proposals`)
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ final_price: '100000.00', reason: 'No additional parts were required' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/orders/${orderId}/price-proposals/${priceProposal.body.proposal.id}/approve`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body.orderStatus).toBe('PAID'));
    await request(app.getHttpServer())
      .post(`/orders/${orderId}/complete`)
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({ status: 'COMPLETED', finalPrice: '100000.00' }));

    const wallet = await request(app.getHttpServer())
      .get('/wallets/me')
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200);
    expect(wallet.body).toMatchObject({
      balance: '100000.00', lockedBalance: '0.00', availableBalance: '100000.00', currency: 'VND', demoOnly: true,
    });
    await request(app.getHttpServer())
      .post('/withdrawals')
      .set('Authorization', `Bearer ${customer.token}`)
      .send({ amount: '40000.00' })
      .expect(403);
    await request(app.getHttpServer())
      .post('/withdrawals')
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ amount: '0.00' })
      .expect(400);
    const withdrawal = await request(app.getHttpServer())
      .post('/withdrawals')
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ amount: '40000.00' })
      .expect(201);
    expect(withdrawal.body).toMatchObject({
      withdrawal: { amount: '40000.00', status: 'PENDING' },
      wallet: { balance: '100000.00', lockedBalance: '40000.00', availableBalance: '60000.00' },
      sandboxOnly: true,
    });
    await request(app.getHttpServer())
      .get('/admin/withdrawals/pending')
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toEqual([
        expect.objectContaining({ id: withdrawal.body.withdrawal.id, provider: expect.objectContaining({ name: 'HTTP Provider' }) }),
      ]));
    await request(app.getHttpServer())
      .patch(`/admin/withdrawals/${withdrawal.body.withdrawal.id}/resolve`)
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ decision: 'APPROVE', reason: 'Sandbox payout reviewed' })
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({
        withdrawal: { status: 'APPROVED' },
        wallet: { balance: '60000.00', lockedBalance: '0.00', availableBalance: '60000.00' },
      }));
    await request(app.getHttpServer())
      .get('/withdrawals/me')
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({
        wallet: { balance: '60000.00', lockedBalance: '0.00', availableBalance: '60000.00' },
        items: [expect.objectContaining({ status: 'APPROVED', amount: '40000.00' })],
      }));
    await request(app.getHttpServer())
      .post(`/orders/${orderId}/reviews`)
      .set('Authorization', `Bearer ${customer.token}`)
      .send({ rating: 5, comment: 'Hỗ trợ nhanh' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/orders/${orderId}/reviews`)
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ rating: 5 })
      .expect(201);
    await request(app.getHttpServer())
      .get(`/orders/${orderId}/messages`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toHaveLength(2));

    const details = await request(app.getHttpServer())
      .get(`/orders/${orderId}`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200);
    expect(details.body).toMatchObject({
      id: orderId,
      status: 'COMPLETED',
      estimatedPrice: '100000.00',
      finalPrice: '100000.00',
      payment: { amount: '100000.00', status: 'PAID', isDemo: true },
    });

    await request(app.getHttpServer())
      .get(`/admin/dashboard/summary?${analyticsQuery()}`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(403);
    const summary = await request(app.getHttpServer())
      .get(`/admin/dashboard/summary?${analyticsQuery()}`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200);
    expect(summary.body).toMatchObject({
      sandboxOnly: true,
      users: { total: 4, customers: 2, providers: 1, admins: 1, createdInPeriod: 4 },
      providers: { total: 1, approved: 1, online: 1, freshLocation: 1 },
      orders: { total: 1, byStatus: { COMPLETED: 1 }, completionRate: 100 },
      money: {
        collectedInPeriod: '100000.00',
        heldCurrent: '0.00',
        settledToProvidersInPeriod: '100000.00',
        refundPendingCurrent: '0.00',
        refundedInPeriod: '0.00',
        grossCompletedValueInPeriod: '100000.00',
        providerWalletBalanceCurrent: '60000.00',
        providerWalletLockedCurrent: '0.00',
        providerWalletAvailableCurrent: '60000.00',
        pendingWithdrawalAmountCurrent: '0.00',
        providerWithdrawnInPeriod: '40000.00',
      },
    });
    const timeseries = await request(app.getHttpServer())
      .get(`/admin/dashboard/timeseries?${analyticsQuery()}&bucket=day`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200);
    expect(timeseries.body.data).toEqual(expect.arrayContaining([
      expect.objectContaining({
        ordersCreated: 1,
        ordersCompleted: 1,
        collected: '100000.00',
        settledToProviders: '100000.00',
        providerWithdrawn: '40000.00',
      }),
    ]));
    const reconciliation = await request(app.getHttpServer())
      .get(`/admin/reconciliation?${analyticsQuery()}&status=PAID&page=1&limit=10`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200);
    expect(reconciliation.body).toMatchObject({
      page: 1,
      limit: 10,
      total: 1,
      totalPages: 1,
      items: [{
        order: { id: orderId, status: 'COMPLETED', finalPrice: '100000.00' },
        payment: { status: 'PAID', amount: '100000.00', paymentCount: 1 },
        settlement: { creditCount: 1, creditedAmount: '100000.00' },
        flags: [],
      }],
    });
  });

  it('cancels before service and completes the full demo refund', async () => {
    const { admin, customer } = await prepareActors();
    const orderId = await createAndMatch(customer.token);

    await request(app.getHttpServer())
      .post(`/orders/${orderId}/cancel`)
      .set('Authorization', `Bearer ${customer.token}`)
      .send({ reason: 'Không cần hỗ trợ nữa' })
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({ status: 'REFUND_PENDING', refundAmount: '100000.00' }));
    const pending = await request(app.getHttpServer())
      .get('/admin/refunds/pending')
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200);
    expect(pending.body).toEqual([expect.objectContaining({ orderId, amount: '100000.00', isDemo: true })]);
    await request(app.getHttpServer())
      .get(`/admin/dashboard/summary?${analyticsQuery()}`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200)
      .expect(({ body }) => expect(body.money).toMatchObject({
        heldCurrent: '100000.00', refundPendingCurrent: '100000.00', refundedInPeriod: '0.00',
      }));

    await request(app.getHttpServer())
      .post(`/payments/demo/orders/${orderId}/refund`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({ status: 'REFUNDED', amount: '100000.00' }));
    await request(app.getHttpServer())
      .get(`/orders/${orderId}`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({ status: 'REFUNDED', payment: { status: 'REFUNDED' } }));
    await request(app.getHttpServer())
      .get(`/admin/dashboard/summary?${analyticsQuery()}`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200)
      .expect(({ body }) => expect(body.money).toMatchObject({
        heldCurrent: '0.00', refundPendingCurrent: '0.00', refundedInPeriod: '100000.00',
      }));
    await request(app.getHttpServer())
      .get(`/admin/reconciliation?${analyticsQuery()}&status=REFUNDED`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({
        total: 1,
        items: [{ order: { id: orderId, status: 'REFUNDED' }, payment: { status: 'REFUNDED' }, flags: [] }],
      }));
  });

  it('flags a completed order that has no provider wallet credit', async () => {
    const { admin, customer, provider } = await prepareActors();
    const orderId = await createAndMatch(customer.token);
    const offers = await request(app.getHttpServer())
      .get('/providers/me/offers/pending')
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200);
    await request(app.getHttpServer())
      .post(`/orders/${orderId}/offers/${offers.body[0].id}/accept`)
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200);
    await database.query(`UPDATE orders SET status = 'COMPLETED', final_price = estimated_price WHERE id = $1`, [orderId]);

    await request(app.getHttpServer())
      .get(`/admin/reconciliation?${analyticsQuery()}`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200)
      .expect(({ body }) => expect(body.items[0]).toMatchObject({
        order: { id: orderId, status: 'COMPLETED' },
        settlement: { creditCount: 0, creditedAmount: '0.00' },
        flags: ['COMPLETED_WALLET_CREDIT_MISMATCH'],
      }));
    await request(app.getHttpServer())
      .get('/admin/dashboard/summary?from=2026-10-06T12:00:00.000Z&to=2026-10-06T11:00:00.000Z')
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(400);
    await request(app.getHttpServer())
      .get(`/admin/reconciliation?${analyticsQuery()}&limit=101`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(400);
  });

  it('manages Provider professional profiles, verified skills and derived weekly statistics', async () => {
    const { customer, provider } = await prepareActors();
    const skill = await request(app.getHttpServer())
      .post('/admin/provider-skills')
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ code: 'FLAT_TIRE', name: 'Vá và thay lốp xe máy' })
      .expect(201);

    await request(app.getHttpServer())
      .patch('/providers/me/profile')
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ bio: 'Thợ cứu hộ xe máy tại TP.HCM', yearsOfExperience: 5, serviceRadiusKm: 12.5 })
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({
        bio: 'Thợ cứu hộ xe máy tại TP.HCM',
        yearsOfExperience: 5,
        serviceRadiusKm: '12.50',
        tier: 'STANDARD',
      }));
    await request(app.getHttpServer())
      .put('/providers/me/skills')
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ skillIds: [skill.body.id] })
      .expect(200)
      .expect(({ body }) => expect(body.skills).toEqual([
        expect.objectContaining({ id: skill.body.id, verificationStatus: SkillVerificationStatus.PENDING }),
      ]));

    const providerRecord = await database.getRepository(Provider).findOneByOrFail({ userId: provider.userId });
    await request(app.getHttpServer())
      .patch(`/admin/providers/${providerRecord.id}/skills/${skill.body.id}/verification`)
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ verificationStatus: 'VERIFIED' })
      .expect(200);
    await request(app.getHttpServer())
      .patch(`/admin/providers/${providerRecord.id}/tier`)
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ tier: 'GOLD' })
      .expect(200);
    await request(app.getHttpServer())
      .patch(`/admin/providers/${providerRecord.id}/tier`)
      .set('Authorization', `Bearer ${provider.token}`)
      .send({ tier: 'PLATINUM' })
      .expect(403);

    const completedOrder = await database.getRepository(Order).save(database.getRepository(Order).create({
      code: `PROFILE-${Date.now()}`,
      customerId: customer.userId,
      providerId: providerRecord.id,
      incidentTypeId: incident.id,
      status: OrderStatus.COMPLETED,
      customerLocation: { type: 'Point', coordinates: [106.7009, 10.7769] },
      basePrice: '125000.00',
      estimatedPrice: '125000.00',
      finalPrice: '125000.00',
    }));
    await database.getRepository(Review).save(database.getRepository(Review).create({
      orderId: completedOrder.id,
      reviewerId: customer.userId,
      revieweeId: provider.userId,
      rating: 5,
      comment: 'Tốt',
    }));
    const wallet = await database.getRepository(Wallet).save(
      database.getRepository(Wallet).create({ providerId: providerRecord.id, balance: '125000.00' }),
    );
    await database.getRepository(WalletTransaction).save(database.getRepository(WalletTransaction).create({
      walletId: wallet.id,
      type: WalletTransactionType.CREDIT,
      amount: '125000.00',
      orderId: completedOrder.id,
      withdrawalId: null,
    }));

    await request(app.getHttpServer())
      .get(`/orders/${completedOrder.id}/provider-profile`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({ tier: 'GOLD', reviewCount: 1, averageRating: '5.00' });
        expect(body.skills).toEqual([expect.objectContaining({ code: 'FLAT_TIRE', verificationStatus: 'VERIFIED' })]);
        expect(body).not.toHaveProperty('phone');
        expect(body).not.toHaveProperty('email');
      });
    const stranger = await createActor('Stranger', 'stranger.profile@motocare.test', UserRole.CUSTOMER, UserStatus.ACTIVE);
    await request(app.getHttpServer())
      .get(`/orders/${completedOrder.id}/provider-profile`)
      .set('Authorization', `Bearer ${stranger.token}`)
      .expect(404);

    await request(app.getHttpServer())
      .get('/providers/me/statistics/weekly')
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({
        timezone: 'Asia/Ho_Chi_Minh',
        completedOrders: 1,
        reviewCount: 1,
        averageRating: '5.00',
        creditedAmount: '125000.00',
        debitedAmount: '0.00',
      }));
    await request(app.getHttpServer())
      .get('/providers/me/statistics/weekly?week_start=2026-10-06')
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(400);
  });

  it('queries informational service locations by viewport and PostGIS distance', async () => {
    const customer = await createActor(
      'Map Customer', 'map.customer@motocare.test', UserRole.CUSTOMER, UserStatus.ACTIVE,
    );
    const repository = database.getRepository(ServiceLocation);
    await repository.save([
      repository.create({
        source: ServiceLocationSource.OSM,
        sourceId: 'node/near',
        type: ServiceLocationType.REPAIR_SHOP,
        name: 'Tiệm sửa xe gần',
        address: 'Quận 1',
        location: { type: 'Point', coordinates: [106.7009, 10.7769] },
        isVerified: false,
        isPartner: false,
        isActive: true,
      }),
      repository.create({
        source: ServiceLocationSource.OSM,
        sourceId: 'node/far',
        type: ServiceLocationType.CHARGING_STATION,
        name: 'Trạm sạc xa hơn',
        address: 'Bình Thạnh',
        location: { type: 'Point', coordinates: [106.7105, 10.8012] },
        isVerified: false,
        isPartner: false,
        isActive: true,
      }),
      repository.create({
        source: ServiceLocationSource.MANUAL,
        sourceId: 'inactive-demo',
        type: ServiceLocationType.FUEL_STATION,
        name: 'Điểm đã đóng',
        address: null,
        location: { type: 'Point', coordinates: [106.701, 10.777] },
        isVerified: true,
        isPartner: false,
        isActive: false,
      }),
    ]);

    await request(app.getHttpServer())
      .get('/service-locations/nearby?latitude=10.7769&longitude=106.7009&radius_km=10&limit=20')
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => {
        expect(body).toHaveLength(2);
        expect(body[0]).toMatchObject({ name: 'Tiệm sửa xe gần', distanceMeters: 0 });
        expect(body[1].distanceMeters).toBeGreaterThan(0);
      });
    await request(app.getHttpServer())
      .get('/service-locations/nearby?latitude=10.7769&longitude=106.7009&radius_km=10&types=REPAIR_SHOP')
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toEqual([expect.objectContaining({ type: 'REPAIR_SHOP' })]));
    await request(app.getHttpServer())
      .get('/service-locations/viewport?north=10.82&south=10.75&east=106.73&west=106.68')
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toHaveLength(2));
    await request(app.getHttpServer())
      .get('/service-locations/viewport?north=12&south=10&east=108&west=106')
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(400);
    await request(app.getHttpServer())
      .get('/service-locations/nearby?latitude=10.7769&longitude=106.7009')
      .expect(401);
  });

  it('keeps device tokens private and notification inboxes isolated by user', async () => {
    const customer = await createActor(
      'Notification Customer', 'notification.customer@motocare.test', UserRole.CUSTOMER, UserStatus.ACTIVE,
    );
    const stranger = await createActor(
      'Notification Stranger', 'notification.stranger@motocare.test', UserRole.CUSTOMER, UserStatus.ACTIVE,
    );
    const token = 'fcm-test-token-that-is-long-enough-and-must-never-be-returned';
    await request(app.getHttpServer())
      .put('/notifications/devices')
      .set('Authorization', `Bearer ${customer.token}`)
      .send({ installationId: 'notification-installation-0001', fcmToken: token, platform: 'ANDROID' })
      .expect(200)
      .expect(({ body }) => {
        expect(body).toMatchObject({ installationId: 'notification-installation-0001', isEnabled: true });
        expect(body).not.toHaveProperty('fcmToken');
        expect(JSON.stringify(body)).not.toContain(token);
      });

    const notification = await database.getRepository(Notification).save(
      database.getRepository(Notification).create({
        userId: customer.userId,
        type: NotificationType.SYSTEM,
        title: 'MotoCare',
        body: 'Thông báo kiểm thử',
        data: { route: 'home' },
        dedupeKey: 'http-test-notification',
        readAt: null,
        expiresAt: null,
      }),
    );

    await request(app.getHttpServer())
      .get('/notifications?limit=10')
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => {
        expect(body.unreadCount).toBe(1);
        expect(body.items).toEqual([expect.objectContaining({ id: notification.id, type: 'SYSTEM' })]);
      });
    await request(app.getHttpServer())
      .get('/notifications?unreadOnly=not-a-boolean')
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(400);
    await request(app.getHttpServer())
      .patch(`/notifications/${notification.id}/read`)
      .set('Authorization', `Bearer ${stranger.token}`)
      .expect(404);
    await request(app.getHttpServer())
      .patch(`/notifications/${notification.id}/read`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body.readAt).not.toBeNull());
    await request(app.getHttpServer())
      .delete('/notifications/devices/notification-installation-0001')
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body.isEnabled).toBe(false));
  });

  it('deduplicates durable notifications and delivers queued push once', async () => {
    const customer = await createActor(
      'Push Customer', 'push.customer@motocare.test', UserRole.CUSTOMER, UserStatus.ACTIVE,
    );
    const sent: Array<{ token: string; message: PushMessage }> = [];
    const push = {
      enabled: true,
      async send(token: string, message: PushMessage) {
        sent.push({ token, message });
        return { success: true };
      },
    } as PushGateway;
    const notifications = new NotificationsService(database, push, app.get(ConfigService));
    await notifications.registerDevice(customer.userId, {
      installationId: 'push-installation-0001',
      fcmToken: 'fcm-push-token-that-is-long-enough-for-validation',
      platform: DevicePlatform.ANDROID,
    });

    const input = {
      userId: customer.userId,
      type: NotificationType.SYSTEM,
      title: 'MotoCare',
      body: 'Delivery test',
      dedupeKey: 'delivery-dedupe-test',
    };
    const first = await notifications.create(input);
    const duplicate = await notifications.create(input);
    expect(duplicate.id).toBe(first.id);
    expect(await database.getRepository(Notification).countBy({ dedupeKey: input.dedupeKey })).toBe(1);
    expect(await database.getRepository(NotificationDelivery).countBy({ notificationId: first.id })).toBe(1);

    await new NotificationDeliveryService(database, push).deliverPending();

    expect(sent).toHaveLength(1);
    expect(sent[0].token).toBe('fcm-push-token-that-is-long-enough-for-validation');
    expect(sent[0].message.data.notificationId).toBe(String(first.id));
    const delivery = await database.getRepository(NotificationDelivery).findOneByOrFail({ notificationId: first.id });
    expect(delivery.status).toBe(NotificationDeliveryStatus.SENT);
    expect(delivery.sentAt).not.toBeNull();
  });
});
