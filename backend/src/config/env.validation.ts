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
  CHAT_UPLOAD_DIR: Joi.string().trim().min(1).default('storage/chat'),
  CHAT_IMAGE_MAX_BYTES: Joi.number().integer().min(1024).max(5_242_880).default(5_242_880),
  EMAIL_ENABLED: Joi.boolean().default(false),
  SMTP_HOST: Joi.when('EMAIL_ENABLED', { is: true, then: Joi.string().required(), otherwise: Joi.string().optional() }),
  SMTP_PORT: Joi.number().port().default(587),
  SMTP_SECURE: Joi.boolean().default(false),
  SMTP_USER: Joi.when('EMAIL_ENABLED', { is: true, then: Joi.string().required(), otherwise: Joi.string().optional() }),
  SMTP_PASSWORD: Joi.when('EMAIL_ENABLED', { is: true, then: Joi.string().required(), otherwise: Joi.string().optional() }),
  SMTP_FROM: Joi.when('EMAIL_ENABLED', { is: true, then: Joi.string().required(), otherwise: Joi.string().optional() }),
});
