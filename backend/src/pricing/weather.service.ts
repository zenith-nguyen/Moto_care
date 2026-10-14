import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WeatherCategory } from './weather-category.enum';

export const WEATHER_FETCHER = Symbol('WEATHER_FETCHER');

export type WeatherFetcher = (input: string, init?: RequestInit) => Promise<{ ok: boolean; json: () => Promise<unknown> }>;

export interface WeatherSnapshot {
  category: WeatherCategory;
  source: 'OPEN_METEO' | 'FALLBACK';
  observedAt: Date | null;
  weatherCode: number | null;
  precipitationMm: number | null;
  windSpeedKmh: number | null;
  windGustKmh: number | null;
}

type CurrentWeatherResponse = {
  current?: {
    time?: unknown;
    weather_code?: unknown;
    precipitation?: unknown;
    rain?: unknown;
    wind_speed_10m?: unknown;
    wind_gusts_10m?: unknown;
  };
};

type CachedWeather = { expiresAt: number; value: WeatherSnapshot };

const severeCodes = new Set([65, 67, 82, 86, 95, 96, 99]);
const wetCodes = new Set([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99]);

export function classifyWeather(input: {
  weatherCode: number;
  precipitationMm: number;
  rainMm: number;
  windSpeedKmh: number;
  windGustKmh: number;
}): WeatherCategory {
  if (severeCodes.has(input.weatherCode) || input.precipitationMm >= 7.5 || input.windSpeedKmh >= 40 || input.windGustKmh >= 60) {
    return WeatherCategory.SEVERE;
  }
  if (
    wetCodes.has(input.weatherCode) ||
    input.precipitationMm >= 0.1 ||
    input.rainMm >= 0.1 ||
    input.windSpeedKmh >= 25 ||
    input.windGustKmh >= 40
  ) {
    return WeatherCategory.MODERATE;
  }
  return WeatherCategory.NORMAL;
}

@Injectable()
export class WeatherService {
  private readonly cache = new Map<string, CachedWeather>();

  constructor(
    private readonly config: ConfigService,
    @Inject(WEATHER_FETCHER) private readonly fetcher: WeatherFetcher,
  ) {}

  async current(latitude: number, longitude: number): Promise<WeatherSnapshot> {
    if (!(this.config.get<boolean>('WEATHER_PRICING_ENABLED') ?? false)) {
      return this.fallback(WeatherCategory.DISABLED);
    }

    const roundedLatitude = Number(latitude.toFixed(2));
    const roundedLongitude = Number(longitude.toFixed(2));
    const cacheKey = `${roundedLatitude.toFixed(2)},${roundedLongitude.toFixed(2)}`;
    const cached = this.cache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) return cached.value;
    if (cached) this.cache.delete(cacheKey);

    const timeoutMs = this.config.get<number>('WEATHER_REQUEST_TIMEOUT_MS') ?? 1500;
    const cacheTtlSeconds = this.config.get<number>('WEATHER_CACHE_TTL_SECONDS') ?? 300;
    const query = new URLSearchParams({
      latitude: roundedLatitude.toString(),
      longitude: roundedLongitude.toString(),
      current: 'weather_code,precipitation,rain,wind_speed_10m,wind_gusts_10m',
      wind_speed_unit: 'kmh',
      timezone: 'UTC',
    });

    let snapshot: WeatherSnapshot;
    try {
      const response = await this.fetcher(`https://api.open-meteo.com/v1/forecast?${query.toString()}`, {
        signal: AbortSignal.timeout(timeoutMs),
        headers: { 'User-Agent': 'MotoCare-educational-demo/1.0' },
      });
      if (!response.ok) throw new Error('Weather provider returned a non-success response');
      snapshot = this.parse(await response.json());
    } catch {
      snapshot = this.fallback(WeatherCategory.UNAVAILABLE);
    }

    if (this.cache.size >= 500) this.removeOldestCacheEntry();
    this.cache.set(cacheKey, {
      expiresAt: Date.now() + cacheTtlSeconds * 1000,
      value: snapshot,
    });
    return snapshot;
  }

  private parse(value: unknown): WeatherSnapshot {
    const current = (value as CurrentWeatherResponse | null)?.current;
    const weatherCode = this.weatherCode(current?.weather_code);
    const precipitationMm = this.nonNegativeNumber(current?.precipitation);
    const rainMm = this.nonNegativeNumber(current?.rain);
    const windSpeedKmh = this.nonNegativeNumber(current?.wind_speed_10m);
    const windGustKmh = this.nonNegativeNumber(current?.wind_gusts_10m);
    const observedAt = this.utcDate(current?.time);
    if (
      weatherCode === null ||
      precipitationMm === null ||
      rainMm === null ||
      windSpeedKmh === null ||
      windGustKmh === null ||
      observedAt === null
    ) {
      throw new Error('Weather provider response is incomplete');
    }
    return {
      category: classifyWeather({
        weatherCode,
        precipitationMm,
        rainMm,
        windSpeedKmh,
        windGustKmh,
      }),
      source: 'OPEN_METEO',
      observedAt,
      weatherCode,
      precipitationMm,
      windSpeedKmh,
      windGustKmh,
    };
  }

  private fallback(category: WeatherCategory.DISABLED | WeatherCategory.UNAVAILABLE): WeatherSnapshot {
    return {
      category,
      source: 'FALLBACK',
      observedAt: null,
      weatherCode: null,
      precipitationMm: null,
      windSpeedKmh: null,
      windGustKmh: null,
    };
  }

  private number(value: unknown): number | null {
    return typeof value === 'number' && Number.isFinite(value) ? value : null;
  }

  private nonNegativeNumber(value: unknown): number | null {
    const parsed = this.number(value);
    return parsed !== null && parsed >= 0 && parsed <= 1000 ? parsed : null;
  }

  private weatherCode(value: unknown): number | null {
    const parsed = this.number(value);
    return parsed !== null && Number.isInteger(parsed) && parsed >= 0 && parsed <= 255 ? parsed : null;
  }

  private utcDate(value: unknown): Date | null {
    if (typeof value !== 'string') return null;
    const date = new Date(value.endsWith('Z') ? value : `${value}Z`);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  private removeOldestCacheEntry(): void {
    const firstKey = this.cache.keys().next().value as string | undefined;
    if (firstKey) this.cache.delete(firstKey);
  }
}
