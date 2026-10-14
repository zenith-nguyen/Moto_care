import { ConfigService } from '@nestjs/config';
import { jest } from '@jest/globals';
import { WeatherCategory } from './weather-category.enum';
import { classifyWeather, WeatherFetcher, WeatherService } from './weather.service';

describe('WeatherService', () => {
  it('classifies normal, moderate and severe weather', () => {
    expect(
      classifyWeather({
        weatherCode: 1,
        precipitationMm: 0,
        rainMm: 0,
        windSpeedKmh: 5,
        windGustKmh: 10,
      }),
    ).toBe(WeatherCategory.NORMAL);
    expect(
      classifyWeather({
        weatherCode: 61,
        precipitationMm: 1,
        rainMm: 1,
        windSpeedKmh: 5,
        windGustKmh: 10,
      }),
    ).toBe(WeatherCategory.MODERATE);
    expect(
      classifyWeather({
        weatherCode: 95,
        precipitationMm: 1,
        rainMm: 1,
        windSpeedKmh: 5,
        windGustKmh: 10,
      }),
    ).toBe(WeatherCategory.SEVERE);
  });

  it('rounds coordinates, caches responses and parses provider data', async () => {
    const fetcher = jest.fn<WeatherFetcher>(async () => ({
      ok: true,
      json: async () => ({
        current: {
          time: '2026-10-06T08:00',
          weather_code: 61,
          precipitation: 1.2,
          rain: 1.2,
          wind_speed_10m: 12,
          wind_gusts_10m: 20,
        },
      }),
    }));
    const service = new WeatherService(
      new ConfigService({
        WEATHER_PRICING_ENABLED: true,
        WEATHER_REQUEST_TIMEOUT_MS: 1000,
        WEATHER_CACHE_TTL_SECONDS: 300,
      }),
      fetcher,
    );
    const first = await service.current(10.7769, 106.7009);
    const second = await service.current(10.7771, 106.7011);
    expect(first.category).toBe(WeatherCategory.MODERATE);
    expect(second).toEqual(first);
    expect(fetcher).toHaveBeenCalledTimes(1);
    expect(fetcher.mock.calls[0][0]).toContain('latitude=10.78');
    expect(fetcher.mock.calls[0][0]).toContain('longitude=106.7');
  });

  it('falls back to no surcharge when the provider is unavailable', async () => {
    const fetcher: WeatherFetcher = async () => {
      throw new Error('offline');
    };
    const service = new WeatherService(new ConfigService({ WEATHER_PRICING_ENABLED: true }), fetcher);
    await expect(service.current(10.77, 106.7)).resolves.toMatchObject({
      category: WeatherCategory.UNAVAILABLE,
      source: 'FALLBACK',
    });
  });

  it('rejects incomplete or out-of-range provider data', async () => {
    const fetcher: WeatherFetcher = async () => ({
      ok: true,
      json: async () => ({ current: { time: '2026-10-06T08:00', weather_code: 1.5 } }),
    });
    const service = new WeatherService(new ConfigService({ WEATHER_PRICING_ENABLED: true }), fetcher);
    await expect(service.current(10.77, 106.7)).resolves.toMatchObject({ category: WeatherCategory.UNAVAILABLE });
  });
});
