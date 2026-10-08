import { envValidationSchema } from "./env.validation";

const requiredEnvironment = {
  DATABASE_HOST: "localhost",
  DATABASE_NAME: "motocare_test",
  DATABASE_USER: "motocare",
  DATABASE_PASSWORD: "local-test-password",
  JWT_SECRET: "j".repeat(64),
};

describe("environment validation", () => {
  it("rejects wildcard CORS origins", () => {
    const result = envValidationSchema.validate({
      ...requiredEnvironment,
      CORS_ORIGIN: "*",
    });
    expect(result.error).toBeDefined();
  });

  it("rejects demo mode and missing purpose-specific HMAC secrets in production", () => {
    const result = envValidationSchema.validate(
      {
        ...requiredEnvironment,
        NODE_ENV: "production",
        DEMO_MODE: true,
      },
      { abortEarly: false },
    );
    const message = result.error?.message ?? "";
    expect(message).toContain("DEMO_MODE");
    expect(message).toContain("ORDER_START_HMAC_SECRET");
    expect(message).toContain("PASSWORD_RESET_HMAC_SECRET");
  });

  it("accepts separate production secrets and exact HTTPS origins", () => {
    const result = envValidationSchema.validate({
      ...requiredEnvironment,
      NODE_ENV: "production",
      DEMO_MODE: false,
      CORS_ORIGIN: "https://customer.example,https://admin.example",
      ORDER_START_HMAC_SECRET: "o".repeat(64),
      PASSWORD_RESET_HMAC_SECRET: "p".repeat(64),
    });
    expect(result.error).toBeUndefined();
  });

  it('keeps SePay disabled by default and requires all Test mode secrets when enabled', () => {
    const disabled = envValidationSchema.validate(requiredEnvironment);
    expect(disabled.error).toBeUndefined();
    expect(disabled.value.SEPAY_ENABLED).toBe(false);

    const incomplete = envValidationSchema.validate(
      {
        ...requiredEnvironment,
        SEPAY_ENABLED: true,
      },
      { abortEarly: false },
    );
    const message = incomplete.error?.message ?? '';
    expect(message).toContain('SEPAY_BANK');
    expect(message).toContain('SEPAY_ACCOUNT_NUMBER');
    expect(message).toContain('SEPAY_ACCOUNT_HOLDER');
    expect(message).toContain('SEPAY_WEBHOOK_SECRET');

    const enabled = envValidationSchema.validate({
      ...requiredEnvironment,
      SEPAY_ENABLED: true,
      SEPAY_MODE: 'test',
      SEPAY_BANK: 'MBBank',
      SEPAY_ACCOUNT_NUMBER: 'SBSEPAYX9KA2B7MN4QR',
      SEPAY_ACCOUNT_HOLDER: 'MOTOCARE DEMO',
      SEPAY_WEBHOOK_SECRET: 's'.repeat(32),
    });
    expect(enabled.error).toBeUndefined();
  });

  it('rejects real bank account numbers for the Test mode QR adapter', () => {
    const result = envValidationSchema.validate({
      ...requiredEnvironment,
      SEPAY_ENABLED: true,
      SEPAY_MODE: 'test',
      SEPAY_BANK: 'MBBank',
      SEPAY_ACCOUNT_NUMBER: '0123456789',
      SEPAY_ACCOUNT_HOLDER: 'MOTOCARE DEMO',
      SEPAY_WEBHOOK_SECRET: 's'.repeat(32),
    });

    expect(result.error?.message).toContain('SEPAY_ACCOUNT_NUMBER');
  });
});
