import { Injectable } from '@nestjs/common';
import { centsToMoney, moneyToCents } from '../common/utils/money';
import { WeatherCategory } from './weather-category.enum';
import { WeatherService, WeatherSnapshot } from './weather.service';

export interface OrderPriceQuote {
  basePrice: string;
  estimatedPrice: string;
  weatherSurcharge: string;
  weatherMultiplier: string;
  weather: WeatherSnapshot;
}

const multiplierBasisPoints: Record<WeatherCategory, bigint> = {
  [WeatherCategory.DISABLED]: 10_000n,
  [WeatherCategory.UNAVAILABLE]: 10_000n,
  [WeatherCategory.NORMAL]: 10_000n,
  [WeatherCategory.MODERATE]: 11_000n,
  [WeatherCategory.SEVERE]: 12_000n,
};

@Injectable()
export class OrderPricingService {
  constructor(private readonly weather: WeatherService) {}

  weatherAt(latitude: number, longitude: number): Promise<WeatherSnapshot> {
    return this.weather.current(latitude, longitude);
  }

  quote(basePrice: string, weather: WeatherSnapshot): OrderPriceQuote {
    const baseCents = moneyToCents(basePrice);
    const basisPoints = multiplierBasisPoints[weather.category];
    const estimatedCents = (baseCents * basisPoints + 5_000n) / 10_000n;
    return {
      basePrice: centsToMoney(baseCents),
      estimatedPrice: centsToMoney(estimatedCents),
      weatherSurcharge: centsToMoney(estimatedCents - baseCents),
      weatherMultiplier: `${basisPoints / 10_000n}.${(basisPoints % 10_000n).toString().padStart(4, '0')}`,
      weather,
    };
  }

}
