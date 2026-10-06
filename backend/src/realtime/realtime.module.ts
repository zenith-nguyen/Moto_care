import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Message } from '../messages/message.entity';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Order } from '../orders/order.entity';
import { Provider } from '../providers/provider.entity';
import { User } from '../users/user.entity';
import { RealtimeGateway } from './realtime.gateway';
import { MessagesController } from '../messages/messages.controller';
import { MessagesService } from '../messages/messages.service';
import { ChatImageStorageService } from '../messages/chat-image-storage.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Message, Order, Provider, User]),
    MulterModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        limits: {
          fileSize: Number(config.get('CHAT_IMAGE_MAX_BYTES') ?? 5_242_880),
          files: 1,
          fields: 2,
          fieldSize: 8_192,
          parts: 3,
        },
      }),
    }),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({ secret: config.getOrThrow<string>('JWT_SECRET') }),
    }),
  ],
  controllers: [MessagesController],
  providers: [RealtimeGateway, MessagesService, ChatImageStorageService],
  exports: [RealtimeGateway],
})
export class RealtimeModule {}
