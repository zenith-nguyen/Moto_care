import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrderOffer } from '../orders/order-offer.entity';
import { User } from '../users/user.entity';
import { Provider } from './provider.entity';
import { ProvidersController } from './providers.controller';
import { ProvidersService } from './providers.service';

@Module({
  imports: [TypeOrmModule.forFeature([Provider, OrderOffer, User])],
  controllers: [ProvidersController],
  providers: [ProvidersService],
})
export class ProvidersModule {}
