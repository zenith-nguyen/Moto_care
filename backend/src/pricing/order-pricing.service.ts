import { Injectable } from '@nestjs/common';
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
    const baseCents = this.parseMoney(basePrice);
    const basisPoints = multiplierBasisPoints[weather.category];
    const estimatedCents = (baseCents * basisPoints + 5_000n) / 10_000n;
    return {
      basePrice: this.formatMoney(baseCents),
      estimatedPrice: this.formatMoney(estimatedCents),
      weatherSurcharge: this.formatMoney(estimatedCents - baseCents),
      weatherMultiplier: `${basisPoints / 10_000n}.${(basisPoints % 10_000n).toString().padStart(4, '0')}`,
      weather,
    };
  }

  private parseMoney(value: string): bigint {
    const match = /^(0|[1-9]\d*)(?:\.(\d{1,2}))?$/.exec(value);
    if (!match) throw new Error('Invalid decimal money value');
    const fraction = (match[2] ?? '').padEnd(2, '0');
    return BigInt(match[1]) * 100n + BigInt(fraction);
  }

  private formatMoney(cents: bigint): string {
    const whole = cents / 100n;
    const fraction = (cents % 100n).toString().padStart(2, '0');
    return `${whole}.${fraction}`;
  }
}
