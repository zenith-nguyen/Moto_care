import 'dotenv/config';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const testDatabase = process.env.TEST_DATABASE_NAME;
if (!testDatabase || !/^motocare_[a-z0-9_]*test$/.test(testDatabase)) {
  throw new Error('Set TEST_DATABASE_NAME to a dedicated MotoCare test database');
}

// ConfigModule in the HTTP integration test intentionally skips Joi coercion.
// Remove developer-machine feature flags so string values such as "false" do
// not become truthy and make DB tests call external services.
delete process.env.WEATHER_PRICING_ENABLED;
delete process.env.EMAIL_ENABLED;
delete process.env.PUSH_NOTIFICATIONS_ENABLED;

Object.assign(process.env, {
  NODE_ENV: 'test',
  DATABASE_NAME: testDatabase,
  DEMO_MODE: 'true',
  JWT_SECRET: 'http-test-only-jwt-secret-longer-than-32-characters',
  JWT_EXPIRES_IN: '1d',
  OFFER_TTL_SECONDS: '60',
  PROVIDER_LOCATION_MAX_AGE_SECONDS: '120',
  MATCH_RADIUS_KM: '10',
  PROVIDER_NEARBY_RADIUS_METERS: '300',
  CHAT_UPLOAD_DIR: join(tmpdir(), `motocare-chat-http-test-${process.pid}`),
  CHAT_IMAGE_MAX_BYTES: '5242880',
  SEPAY_ENABLED: 'true',
  SEPAY_MODE: 'test',
  SEPAY_BANK: 'MBBank',
  SEPAY_ACCOUNT_NUMBER: 'SBSEPAYX9KA2B7MN4QR',
  SEPAY_ACCOUNT_HOLDER: 'MOTOCARE TEST',
  SEPAY_PAYMENT_CODE_PREFIX: 'MC',
  SEPAY_TRANSFER_MEMO_PREFIX: '',
  SEPAY_WEBHOOK_SECRET: 'db-test-only-sepay-webhook-secret-32-characters',
  SEPAY_WEBHOOK_MAX_AGE_SECONDS: '300',
});
