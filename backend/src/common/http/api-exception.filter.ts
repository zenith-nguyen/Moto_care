import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import type { Response } from "express";
import type { RequestWithId } from "./request-context.middleware";

type HttpExceptionBody = {
  message?: string | string[];
};

@Catch()
export class ApiExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(ApiExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const request = context.getRequest<RequestWithId>();
    const response = context.getResponse<Response>();
    const statusCode =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;
    const path = (request.originalUrl || request.url).split("?")[0];

    if (statusCode >= HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(
        JSON.stringify({
          event: "http_exception",
          requestId: request.requestId,
          path,
          statusCode,
          exception:
            exception instanceof Error ? exception.name : "UnknownError",
        }),
      );
    }

    response.status(statusCode).json({
      statusCode,
      code: HttpStatus[statusCode] ?? "HTTP_ERROR",
      message: this.safeMessage(exception, statusCode),
      path,
      requestId: request.requestId,
      timestamp: new Date().toISOString(),
    });
  }

  private safeMessage(
    exception: unknown,
    statusCode: number,
  ): string | string[] {
    if (!(exception instanceof HttpException)) return "Internal server error";
    if (statusCode >= HttpStatus.INTERNAL_SERVER_ERROR)
      return "Internal server error";

    const body = exception.getResponse();
    if (typeof body === "string") return body;
    if (this.isHttpExceptionBody(body) && body.message) return body.message;
    return exception.message || "Request failed";
  }

  private isHttpExceptionBody(value: object): value is HttpExceptionBody {
    if (!("message" in value)) return false;
    const message = value.message;
    return (
      typeof message === "string" ||
      (Array.isArray(message) &&
        message.every((item) => typeof item === "string"))
    );
  }
}
