import { Module } from '@nestjs/common';
import { OrderPricingService } from './order-pricing.service';
import { WEATHER_FETCHER, WeatherFetcher, WeatherService } from './weather.service';
import { PricingController } from './pricing.controller';

@Module({
  controllers: [PricingController],
  providers: [
    {
      provide: WEATHER_FETCHER,
      useValue: ((input: string, init?: RequestInit) => fetch(input, init)) satisfies WeatherFetcher,
    },
    WeatherService,
    OrderPricingService,
  ],
  exports: [OrderPricingService, WeatherService],
})
export class PricingModule {}
