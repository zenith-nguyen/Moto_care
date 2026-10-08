import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { configureApp } from './configure-app';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { rawBody: true });
  const configService = app.get(ConfigService);
  configureApp(app, configService);

  if (configService.get<string>('NODE_ENV') !== 'production' && !configService.get<boolean>('DEMO_MODE')) {
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
