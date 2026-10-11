import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ServiceLocation } from './service-location.entity';
import { ServiceLocationsController } from './service-locations.controller';
import { ServiceLocationsService } from './service-locations.service';

@Module({
  imports: [TypeOrmModule.forFeature([ServiceLocation])],
  controllers: [ServiceLocationsController],
  providers: [ServiceLocationsService],
})
export class ServiceLocationsModule {}
