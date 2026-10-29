import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { configureApp } from './configure-app';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { rawBody: true });
  const configService = app.get(ConfigService);
  configureApp(app, configService);

  // Swagger UI is served at /docs in any non-production environment (including
  // DEMO_MODE). In production it is off by default, but can be turned on
  // explicitly with SWAGGER_ENABLED=true (e.g. for a live demo).
  if (
    configService.get<string>('NODE_ENV') !== 'production' ||
    configService.get<boolean>('SWAGGER_ENABLED') === true
  ) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('MotoCare API')
      .setDescription('MotoCare mobile roadside-assistance backend')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, swaggerConfig));
  }

  await app.listen(configService.getOrThrow<number>('PORT'));
}

void bootstrap();
