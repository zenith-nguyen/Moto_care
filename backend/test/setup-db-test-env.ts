import 'dotenv/config';

const testDatabase = process.env.TEST_DATABASE_NAME;
if (!testDatabase || !/^motocare_[a-z0-9_]*test$/.test(testDatabase)) {
  throw new Error('Set TEST_DATABASE_NAME to a dedicated MotoCare test database');
}

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
