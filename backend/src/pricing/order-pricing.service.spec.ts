import { ConfigService } from '@nestjs/config';
import { WeatherCategory } from './weather-category.enum';
import { OrderPricingService } from './order-pricing.service';
import { WeatherFetcher, WeatherService } from './weather.service';

const unusedFetcher: WeatherFetcher = async () => {
  throw new Error('Unexpected weather request');
};

describe('OrderPricingService', () => {
  const weatherService = new WeatherService(new ConfigService({ WEATHER_PRICING_ENABLED: false }), unusedFetcher);
  const pricing = new OrderPricingService(weatherService);

  it.each([
    [WeatherCategory.NORMAL, '1.0000', '100000.00', '0.00'],
    [WeatherCategory.MODERATE, '1.1000', '110000.00', '10000.00'],
    [WeatherCategory.SEVERE, '1.2000', '120000.00', '20000.00'],
    [WeatherCategory.UNAVAILABLE, '1.0000', '100000.00', '0.00'],
  ])('quotes %s without floating point money', (category, multiplier, estimatedPrice, surcharge) => {
    const result = pricing.quote('100000.00', {
      category,
      source: category === WeatherCategory.UNAVAILABLE ? 'FALLBACK' : 'OPEN_METEO',
      observedAt: null,
      weatherCode: null,
      precipitationMm: null,
      windSpeedKmh: null,
      windGustKmh: null,
    });
    expect(result).toMatchObject({
      basePrice: '100000.00',
      estimatedPrice,
      weatherSurcharge: surcharge,
      weatherMultiplier: multiplier,
    });
  });

  it('rounds to the nearest cent using integer arithmetic', () => {
    const result = pricing.quote('0.05', {
      category: WeatherCategory.MODERATE,
      source: 'OPEN_METEO',
      observedAt: null,
      weatherCode: 61,
      precipitationMm: 1,
      windSpeedKmh: 1,
      windGustKmh: 1,
    });
    expect(result.estimatedPrice).toBe('0.06');
  });
});
