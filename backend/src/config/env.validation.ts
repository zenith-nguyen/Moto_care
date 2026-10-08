import * as Joi from 'joi';

const corsOrigins = Joi.string().custom((value: string, helpers) => {
  const origins = value.split(',').map((origin) => origin.trim()).filter(Boolean);
  if (origins.length === 0 || origins.includes('*')) return helpers.error('any.invalid');
  try {
    const valid = origins.every((origin) => {
      const url = new URL(origin);
      return ['http:', 'https:'].includes(url.protocol) && url.origin === origin;
    });
    return valid ? value : helpers.error('any.invalid');
  } catch {
    return helpers.error('any.invalid');
  }
}, 'comma-separated HTTP(S) origins');

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'production').default('development'),
  PORT: Joi.number().port().default(3000),
  CORS_ORIGIN: corsOrigins.default('http://localhost:3000'),
  DATABASE_HOST: Joi.string().required(),
  DATABASE_PORT: Joi.number().port().default(5432),
  DATABASE_NAME: Joi.string().required(),
  DATABASE_USER: Joi.string().required(),
  DATABASE_PASSWORD: Joi.when('NODE_ENV', {
    is: 'production',
    then: Joi.string().min(16).required(),
    otherwise: Joi.string().required(),
  }),
  JWT_SECRET: Joi.when('NODE_ENV', {
    is: 'production',
    then: Joi.string().min(64).required(),
    otherwise: Joi.string().min(32).required(),
  }),
  JWT_EXPIRES_IN: Joi.string().default('1d'),
  ORDER_START_HMAC_SECRET: Joi.when('NODE_ENV', {
    is: 'production',
    then: Joi.string().min(64).required(),
    otherwise: Joi.string().min(32).optional(),
  }),
  PASSWORD_RESET_HMAC_SECRET: Joi.when('NODE_ENV', {
    is: 'production',
    then: Joi.string().min(64).required(),
    otherwise: Joi.string().min(32).optional(),
  }),
  DEMO_MODE: Joi.when('NODE_ENV', {
    is: 'production',
    then: Joi.boolean().valid(false).required(),
    otherwise: Joi.boolean().default(false),
  }),
  API_RATE_LIMIT: Joi.number().integer().min(10).max(10_000).default(120),
  API_RATE_LIMIT_TTL_MS: Joi.number().integer().min(1_000).max(3_600_000).default(60_000),
  MATCH_RADIUS_KM: Joi.number().positive().max(100).default(10),
  OFFER_TTL_SECONDS: Joi.number().integer().positive().max(300).default(15),
  PROVIDER_LOCATION_MAX_AGE_SECONDS: Joi.number().integer().positive().max(3600).default(120),
  WEATHER_PRICING_ENABLED: Joi.boolean().default(false),
  WEATHER_REQUEST_TIMEOUT_MS: Joi.number().integer().min(500).max(5000).default(1500),
  WEATHER_CACHE_TTL_SECONDS: Joi.number().integer().min(60).max(900).default(300),
  CHAT_UPLOAD_DIR: Joi.string().trim().min(1).default('storage/chat'),
  CHAT_IMAGE_MAX_BYTES: Joi.number().integer().min(1024).max(5_242_880).default(5_242_880),
  EMAIL_ENABLED: Joi.boolean().default(false),
  SMTP_HOST: Joi.when('EMAIL_ENABLED', { is: true, then: Joi.string().required(), otherwise: Joi.string().optional() }),
  SMTP_PORT: Joi.number().port().default(587),
  SMTP_SECURE: Joi.boolean().default(false),
  SMTP_USER: Joi.when('EMAIL_ENABLED', { is: true, then: Joi.string().required(), otherwise: Joi.string().optional() }),
  SMTP_PASSWORD: Joi.when('EMAIL_ENABLED', { is: true, then: Joi.string().required(), otherwise: Joi.string().optional() }),
  SMTP_FROM: Joi.when('EMAIL_ENABLED', { is: true, then: Joi.string().required(), otherwise: Joi.string().optional() }),
  SEPAY_ENABLED: Joi.boolean().default(false),
  SEPAY_MODE: Joi.string().valid('test').default('test'),
  SEPAY_BANK: Joi.when('SEPAY_ENABLED', {
    is: true,
    then: Joi.string().trim().min(2).max(50).required(),
    otherwise: Joi.string().optional(),
  }),
  SEPAY_ACCOUNT_NUMBER: Joi.when('SEPAY_ENABLED', {
    is: true,
    then: Joi.string()
      .trim()
      .uppercase()
      .pattern(/^SBSEPAY[A-Z0-9]{12}$/)
      .required(),
    otherwise: Joi.string().optional(),
  }),
  SEPAY_ACCOUNT_HOLDER: Joi.when('SEPAY_ENABLED', {
    is: true,
    then: Joi.string().trim().min(2).max(100).required(),
    otherwise: Joi.string().optional(),
  }),
  SEPAY_PAYMENT_CODE_PREFIX: Joi.string()
    .pattern(/^[A-Z]{2,5}$/)
    .default('MC'),
  SEPAY_TRANSFER_MEMO_PREFIX: Joi.string()
    .trim()
    .uppercase()
    .pattern(/^[A-Z0-9]{1,30}$/)
    .allow('')
    .default(''),
  SEPAY_WEBHOOK_SECRET: Joi.when('SEPAY_ENABLED', {
    is: true,
    then: Joi.string().min(32).required(),
    otherwise: Joi.string().optional(),
  }),
  SEPAY_WEBHOOK_MAX_AGE_SECONDS: Joi.number().integer().min(30).max(900).default(300),
});
