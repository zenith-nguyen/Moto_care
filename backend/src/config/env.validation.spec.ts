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
});
