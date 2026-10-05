import * as Joi from 'joi';

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string().valid('development', 'test', 'production').default('development'),
  PORT: Joi.number().port().default(3000),
  CORS_ORIGIN: Joi.string().default('http://localhost:3000'),
  DATABASE_HOST: Joi.string().required(),
  DATABASE_PORT: Joi.number().port().default(5432),
  DATABASE_NAME: Joi.string().required(),
  DATABASE_USER: Joi.string().required(),
  DATABASE_PASSWORD: Joi.string().required(),
  JWT_SECRET: Joi.string().min(32).required(),
  JWT_EXPIRES_IN: Joi.string().default('1d'),
  DEMO_MODE: Joi.boolean().default(false),
  MATCH_RADIUS_KM: Joi.number().positive().max(100).default(10),
  OFFER_TTL_SECONDS: Joi.number().integer().positive().max(300).default(15),
  PROVIDER_LOCATION_MAX_AGE_SECONDS: Joi.number().integer().positive().max(3600).default(120),
});
