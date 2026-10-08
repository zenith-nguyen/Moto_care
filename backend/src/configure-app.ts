import { ValidationPipe } from "@nestjs/common";
import type { INestApplication } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import helmet from "helmet";
import { ApiExceptionFilter } from "./common/http/api-exception.filter";
import { requestContextMiddleware } from "./common/http/request-context.middleware";

export function configureApp(
  app: INestApplication,
  config: ConfigService,
): void {
  const server = app.getHttpAdapter().getInstance() as {
    disable(name: string): void;
  };
  server.disable("x-powered-by");
  app.use(helmet({ contentSecurityPolicy: false }));
  app.use(requestContextMiddleware);
  app.enableCors({
    origin: config
      .getOrThrow<string>("CORS_ORIGIN")
      .split(",")
      .map((origin) => origin.trim()),
    methods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Authorization", "Content-Type", "X-Request-ID"],
    exposedHeaders: ["X-Request-ID"],
    credentials: false,
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new ApiExceptionFilter());
}
