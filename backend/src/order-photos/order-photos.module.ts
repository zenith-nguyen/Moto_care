import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from '../orders/order.entity';
import { Provider } from '../providers/provider.entity';
import { IncidentPhotoStorageService } from './incident-photo-storage.service';
import { OrderPhoto } from './order-photo.entity';
import { OrderPhotosController } from './order-photos.controller';
import { OrderPhotosService } from './order-photos.service';

@Module({
  imports: [TypeOrmModule.forFeature([OrderPhoto, Order, Provider])],
  controllers: [OrderPhotosController],
  providers: [OrderPhotosService, IncidentPhotoStorageService],
})
export class OrderPhotosModule {}
