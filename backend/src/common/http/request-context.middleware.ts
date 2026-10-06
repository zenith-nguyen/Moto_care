import { Logger } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import type { NextFunction, Request, Response } from "express";

const requestIdPattern = /^[A-Za-z0-9._:-]{8,128}$/;
const accessLogger = new Logger("HttpAccess");

export type RequestWithId = Request & { requestId?: string };

export function normalizeRequestId(value: unknown): string {
  return typeof value === "string" && requestIdPattern.test(value)
    ? value
    : randomUUID();
}

export function requestContextMiddleware(
  request: RequestWithId,
  response: Response,
  next: NextFunction,
): void {
  const startedAt = process.hrtime.bigint();
  const requestId = normalizeRequestId(request.header("x-request-id"));
  request.requestId = requestId;
  response.setHeader("X-Request-ID", requestId);

  response.once("finish", () => {
    const durationMs = Number(process.hrtime.bigint() - startedAt) / 1_000_000;
    const path = (request.originalUrl || request.url).split("?")[0];
    accessLogger.log(
      JSON.stringify({
        event: "http_request",
        requestId,
        method: request.method,
        path,
        statusCode: response.statusCode,
        durationMs: Math.round(durationMs * 100) / 100,
      }),
    );
  });

  next();
}
