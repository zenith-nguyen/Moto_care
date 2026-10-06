import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IncidentType } from '../incident-types/incident-type.entity';
import { Provider } from '../providers/provider.entity';
import { User } from '../users/user.entity';
import { Payment } from '../payments/payment.entity';
import { RealtimeModule } from '../realtime/realtime.module';
import { PricingModule } from '../pricing/pricing.module';
import { MatchingService } from './matching.service';
import { OfferExpiryService } from './offer-expiry.service';
import { OrderOffer } from './order-offer.entity';
import { Order } from './order.entity';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderPriceProposal } from './order-price-proposal.entity';
import { PaymentAdjustment } from '../payments/payment-adjustment.entity';
import { PriceAdjustmentsService } from './price-adjustments.service';

@Module({
  imports: [TypeOrmModule.forFeature([IncidentType, Order, OrderOffer, OrderPriceProposal, Provider, User, Payment, PaymentAdjustment]), RealtimeModule, PricingModule],
  controllers: [OrdersController],
  providers: [OrdersService, PriceAdjustmentsService, MatchingService, OfferExpiryService],
  exports: [MatchingService, PriceAdjustmentsService],
})
export class OrdersModule {}
