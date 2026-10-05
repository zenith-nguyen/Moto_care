import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as argon2 from 'argon2';
import 'dotenv/config';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { UserRole } from '../src/common/enums/user-role.enum';
import { UserStatus } from '../src/common/enums/user-status.enum';
import { IncidentType } from '../src/incident-types/incident-type.entity';
import { User } from '../src/users/user.entity';

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
  let incident: IncidentType;
  const password = 'HttpTestOnly123!';

  beforeAll(async () => {
    Object.assign(process.env, {
      NODE_ENV: 'test',
      DATABASE_NAME: testDatabase,
      DEMO_MODE: 'true',
      JWT_SECRET: 'http-test-only-jwt-secret-longer-than-32-characters',
      JWT_EXPIRES_IN: '1d',
      OFFER_TTL_SECONDS: '60',
      PROVIDER_LOCATION_MAX_AGE_SECONDS: '120',
      MATCH_RADIUS_KM: '10',
    });

    const { AppModule } = await import('../src/app.module');
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.init();
    database = app.get(DataSource);
  });

  beforeEach(async () => {
    await database.query('TRUNCATE TABLE users, incident_types RESTART IDENTITY CASCADE');
    incident = await database.getRepository(IncidentType).save(
      database.getRepository(IncidentType).create({
        code: 'FLAT_TIRE',
        name: 'Xẹp lốp',
        basePrice: '100000.00',
        isActive: true,
      }),
    );
    await database.getRepository(User).save(
      database.getRepository(User).create({
        name: 'Demo Admin',
        email: 'admin.http-test@motocare.test',
        phone: null,
        passwordHash: await argon2.hash(password),
        role: UserRole.ADMIN,
        status: UserStatus.ACTIVE,
      }),
    );
  });

  afterAll(async () => {
    await app?.close();
  });

  async function register(name: string, email: string, role: UserRole): Promise<Session> {
    const response = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ name, email, password, role })
      .expect(201);
    return { token: response.body.accessToken as string, userId: response.body.user.id as number };
  }

  async function loginAdmin(): Promise<Session> {
    const response = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ identity: 'admin.http-test@motocare.test', password })
      .expect(200);
    return { token: response.body.accessToken as string, userId: response.body.user.id as number };
  }

  async function prepareActors() {
    const customer = await register('HTTP Customer', 'customer.http-test@motocare.test', UserRole.CUSTOMER);
    const provider = await register('HTTP Provider', 'provider.http-test@motocare.test', UserRole.PROVIDER);
    const admin = await loginAdmin();

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
    expect(created.body).toMatchObject({ status: 'AWAITING_PREPAYMENT', estimatedPrice: '100000.00', matched: false });

    const confirmed = await request(app.getHttpServer())
      .post(`/payments/demo/orders/${created.body.id}/confirm`)
      .set('Authorization', `Bearer ${customerToken}`)
      .expect(200);
    expect(confirmed.body).toMatchObject({ status: 'OFFERED', matched: true });
    return created.body.id as number;
  }

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
    await request(app.getHttpServer())
      .post(`/orders/${orderId}/complete`)
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({ status: 'COMPLETED', finalPrice: '100000.00' }));

    const wallet = await request(app.getHttpServer())
      .get('/wallets/me')
      .set('Authorization', `Bearer ${provider.token}`)
      .expect(200);
    expect(wallet.body).toMatchObject({ balance: '100000.00', currency: 'VND', demoOnly: true });
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
      .post(`/payments/demo/orders/${orderId}/refund`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({ status: 'REFUNDED', amount: '100000.00' }));
    await request(app.getHttpServer())
      .get(`/orders/${orderId}`)
      .set('Authorization', `Bearer ${customer.token}`)
      .expect(200)
      .expect(({ body }) => expect(body).toMatchObject({ status: 'REFUNDED', payment: { status: 'REFUNDED' } }));
  });
});
