import { GeoPoint } from '../providers/provider.entity';
import { ServiceLocationSource, ServiceLocationType } from './service-location-type.enum';

export type ServiceLocationImportRecord = {
  source: ServiceLocationSource;
  sourceId: string;
  type: ServiceLocationType;
  name: string;
  address: string | null;
  phone: string | null;
  website: string | null;
  openingHours: string | null;
  location: GeoPoint;
  isVerified: boolean;
  isPartner: boolean;
  isActive: boolean;
  sourceUpdatedAt: Date | null;
};

export interface ServiceLocationImportSource {
  fetchSnapshot(): Promise<ServiceLocationImportRecord[]>;
}

type OsmTags = Record<string, string | undefined>;

export type OsmElement = {
  type: 'node' | 'way' | 'relation';
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat?: number; lon?: number };
  timestamp?: string;
  tags?: OsmTags;
};

type OverpassResponse = { elements?: OsmElement[] };
type Fetcher = typeof fetch;

const repairShops = new Set(['car_repair', 'motorcycle_repair', 'tyres']);
const partsStores = new Set(['car_parts', 'motorcycle_parts']);

export class OsmOverpassSource implements ServiceLocationImportSource {
  constructor(
    private readonly endpoint: string,
    private readonly bbox: string,
    private readonly fetcher: Fetcher = fetch,
  ) {
    const url = new URL(endpoint);
    if (url.protocol !== 'https:') throw new Error('OSM Overpass endpoint must use HTTPS');
  }

  async fetchSnapshot(): Promise<ServiceLocationImportRecord[]> {
    const response = await this.fetcher(this.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
        'User-Agent': 'MotoCareStudentProject/1.0 (service-location snapshot import)',
      },
      body: new URLSearchParams({ data: this.query() }),
      signal: AbortSignal.timeout(120_000),
    });
    if (!response.ok) throw new Error(`OSM Overpass returned HTTP ${response.status}`);
    const payload = await response.json() as OverpassResponse;
    if (!Array.isArray(payload.elements)) throw new Error('OSM Overpass response does not contain elements');
    return payload.elements
      .map(mapOsmElement)
      .filter((record): record is ServiceLocationImportRecord => record !== null);
  }

  private query(): string {
    return `[out:json][timeout:120][bbox:${this.bbox}];
      (
        nwr["amenity"="charging_station"];
        nwr["amenity"="fuel"];
        nwr["shop"~"^(car_repair|motorcycle_repair|tyres|car_parts|motorcycle_parts)$"];
      );
      out center meta;`;
  }
}

export function mapOsmElement(element: OsmElement): ServiceLocationImportRecord | null {
  const tags = element.tags ?? {};
  const latitude = element.lat ?? element.center?.lat;
  const longitude = element.lon ?? element.center?.lon;
  const name = tags.name?.trim();
  const type = classify(tags);
  if (!name || !type || latitude === undefined || longitude === undefined) return null;
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;

  return {
    source: ServiceLocationSource.OSM,
    sourceId: `${element.type}/${element.id}`,
    type,
    name: name.slice(0, 200),
    address: addressFrom(tags),
    phone: nullable(tags.phone ?? tags['contact:phone'], 50),
    website: nullable(tags.website ?? tags['contact:website'], 500),
    openingHours: nullable(tags.opening_hours, 300),
    location: { type: 'Point', coordinates: [longitude, latitude] },
    isVerified: false,
    isPartner: false,
    isActive: true,
    sourceUpdatedAt: element.timestamp ? new Date(element.timestamp) : null,
  };
}

function classify(tags: OsmTags): ServiceLocationType | null {
  if (tags.amenity === 'charging_station') return ServiceLocationType.CHARGING_STATION;
  if (tags.amenity === 'fuel') return ServiceLocationType.FUEL_STATION;
  if (tags.shop && repairShops.has(tags.shop)) return ServiceLocationType.REPAIR_SHOP;
  if (tags.shop && partsStores.has(tags.shop)) return ServiceLocationType.PARTS_STORE;
  return null;
}

function addressFrom(tags: OsmTags): string | null {
  if (tags['addr:full']?.trim()) return tags['addr:full'].trim().slice(0, 1000);
  const street = [tags['addr:housenumber'], tags['addr:street']].filter(Boolean).join(' ');
  const parts = [street, tags['addr:ward'], tags['addr:district'], tags['addr:city']]
    .map((part) => part?.trim())
    .filter((part): part is string => Boolean(part));
  return parts.length ? parts.join(', ').slice(0, 1000) : null;
}

function nullable(value: string | undefined, maxLength: number): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed.slice(0, maxLength) : null;
}
