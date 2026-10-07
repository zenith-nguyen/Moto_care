import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IncidentType } from '../incident-types/incident-type.entity';
import { Provider } from '../providers/provider.entity';
import { User } from '../users/user.entity';
import { PaymentAccountingModule } from '../payments/payment-accounting.module';
import { RealtimeModule } from '../realtime/realtime.module';
import { PricingModule } from '../pricing/pricing.module';
import { MatchingService } from './matching.service';
import { OfferExpiryService } from './offer-expiry.service';
import { OrderOffer } from './order-offer.entity';
import { Order } from './order.entity';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderPriceProposal } from './order-price-proposal.entity';
import { PriceAdjustmentsService } from './price-adjustments.service';
import { OrdersQueryService } from './application/orders-query.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([IncidentType, Order, OrderOffer, OrderPriceProposal, Provider, User]),
    PaymentAccountingModule,
    RealtimeModule,
    PricingModule,
  ],
  controllers: [OrdersController],
  providers: [OrdersService, OrdersQueryService, PriceAdjustmentsService, MatchingService, OfferExpiryService],
  exports: [MatchingService, PriceAdjustmentsService],
})
export class OrdersModule {}
