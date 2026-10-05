import { Module } from '@nestjs/common';
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

@Module({
  imports: [
    TypeOrmModule.forFeature([Message, Order, Provider, User]),
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({ secret: config.getOrThrow<string>('JWT_SECRET') }),
    }),
  ],
  controllers: [MessagesController],
  providers: [RealtimeGateway, MessagesService],
  exports: [RealtimeGateway],
})
export class RealtimeModule {}
