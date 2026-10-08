import { ArgumentsHost, BadRequestException, Logger } from "@nestjs/common";
import { jest } from "@jest/globals";
import { ApiExceptionFilter } from "./api-exception.filter";
import { normalizeRequestId } from "./request-context.middleware";

describe("HTTP hardening", () => {
  it("accepts only bounded safe request IDs", () => {
    expect(normalizeRequestId("mobile-12345678")).toBe("mobile-12345678");
    expect(normalizeRequestId("Bearer secret value")).toMatch(
      /^[0-9a-f-]{36}$/,
    );
    expect(normalizeRequestId("x".repeat(129))).toMatch(/^[0-9a-f-]{36}$/);
  });

  it("hides internal exception details and query parameters", () => {
    jest.spyOn(Logger.prototype, "error").mockImplementation(() => undefined);
    const status = jest.fn().mockReturnThis();
    const json = jest.fn();
    const host = {
      switchToHttp: () => ({
        getRequest: () => ({
          originalUrl: "/orders?token=must-not-leak",
          url: "/orders?token=must-not-leak",
          requestId: "request-12345678",
        }),
        getResponse: () => ({ status, json }),
      }),
    } as unknown as ArgumentsHost;

    new ApiExceptionFilter().catch(new Error("database password leaked"), host);

    expect(status).toHaveBeenCalledWith(500);
    const body = json.mock.calls[0][0] as Record<string, unknown>;
    expect(body).toMatchObject({
      statusCode: 500,
      message: "Internal server error",
      path: "/orders",
      requestId: "request-12345678",
    });
    expect(JSON.stringify(body)).not.toContain("password");
    expect(JSON.stringify(body)).not.toContain("must-not-leak");
  });

  it("preserves safe validation messages", () => {
    const status = jest.fn().mockReturnThis();
    const json = jest.fn();
    const host = {
      switchToHttp: () => ({
        getRequest: () => ({ originalUrl: "/auth/login", url: "/auth/login" }),
        getResponse: () => ({ status, json }),
      }),
    } as unknown as ArgumentsHost;

    new ApiExceptionFilter().catch(
      new BadRequestException(["identity must be an email"]),
      host,
    );

    expect(status).toHaveBeenCalledWith(400);
    expect(json.mock.calls[0][0]).toMatchObject({
      statusCode: 400,
      message: ["identity must be an email"],
      path: "/auth/login",
    });
  });
});
