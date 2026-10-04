import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IncidentType } from '../incident-types/incident-type.entity';
import { Provider } from '../providers/provider.entity';
import { User } from '../users/user.entity';
import { MatchingService } from './matching.service';
import { OfferExpiryService } from './offer-expiry.service';
import { OrderOffer } from './order-offer.entity';
import { Order } from './order.entity';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

@Module({
  imports: [TypeOrmModule.forFeature([IncidentType, Order, OrderOffer, Provider, User])],
  controllers: [OrdersController],
  providers: [OrdersService, MatchingService, OfferExpiryService],
})
export class OrdersModule {}
