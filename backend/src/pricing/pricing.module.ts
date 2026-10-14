import { Module } from '@nestjs/common';
import { OrderPricingService } from './order-pricing.service';
import { WEATHER_FETCHER, WeatherFetcher, WeatherService } from './weather.service';

@Module({
  providers: [
    {
      provide: WEATHER_FETCHER,
      useValue: ((input: string, init?: RequestInit) => fetch(input, init)) satisfies WeatherFetcher,
    },
    WeatherService,
    OrderPricingService,
  ],
  exports: [OrderPricingService],
})
export class PricingModule {}
