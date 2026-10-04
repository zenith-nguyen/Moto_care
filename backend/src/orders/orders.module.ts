import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IncidentType } from '../incident-types/incident-type.entity';
import { OrderOffer } from './order-offer.entity';
import { Order } from './order.entity';

@Module({ imports: [TypeOrmModule.forFeature([IncidentType, Order, OrderOffer])] })
export class OrdersModule {}
