import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrderOffer } from '../orders/order-offer.entity';
import { Order } from '../orders/order.entity';
import { RealtimeModule } from '../realtime/realtime.module';
import { User } from '../users/user.entity';
import { Provider } from './provider.entity';
import { ProvidersController } from './providers.controller';
import { ProvidersService } from './providers.service';
import { ProviderSkill } from './provider-skill.entity';
import { Skill } from './skill.entity';
import { ProviderProfilesService } from './provider-profiles.service';
import { AdminProviderDirectoryController, ProviderDirectoryController } from './provider-directory.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Provider, ProviderSkill, Skill, OrderOffer, Order, User]), RealtimeModule],
  controllers: [ProvidersController, ProviderDirectoryController, AdminProviderDirectoryController],
  providers: [ProvidersService, ProviderProfilesService],
  exports: [ProviderProfilesService],
})
export class ProvidersModule {}
