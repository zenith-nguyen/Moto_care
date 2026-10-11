import { BadRequestException, Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { NearbyServiceLocationsQueryDto, ViewportServiceLocationsQueryDto } from './dto/service-location-query.dto';

type ServiceLocationRow = {
  id: number;
  source: string;
  type: string;
  name: string;
  address: string | null;
  phone: string | null;
  website: string | null;
  opening_hours: string | null;
  longitude: number | string;
  latitude: number | string;
  is_verified: boolean;
  is_partner: boolean;
  distance_meters?: number | string | null;
};

@Injectable()
export class ServiceLocationsService {
  constructor(private readonly database: DataSource) {}

  async inViewport(query: ViewportServiceLocationsQueryDto) {
    if (query.north <= query.south || query.east <= query.west) {
      throw new BadRequestException('Viewport bounds are invalid');
    }
    if (query.north - query.south > 1 || query.east - query.west > 1) {
      throw new BadRequestException('Viewport is too large; zoom into an area no larger than one degree');
    }
    const rows = await this.database.query<ServiceLocationRow[]>(
      `SELECT id, source, type, name, address, phone, website, opening_hours,
              ST_X(location::geometry) AS longitude,
              ST_Y(location::geometry) AS latitude,
              is_verified, is_partner
       FROM service_locations
       WHERE is_active = true
         AND ST_Intersects(location, ST_MakeEnvelope($1, $2, $3, $4, 4326)::geography)
         AND ($5::text[] IS NULL OR type::text = ANY($5::text[]))
       ORDER BY is_partner DESC, is_verified DESC, name ASC, id ASC
       LIMIT 200`,
      [query.west, query.south, query.east, query.north, query.types ?? null],
    );
    return rows.map((row) => this.present(row));
  }

  async nearby(query: NearbyServiceLocationsQueryDto) {
    const radiusMeters = Math.round(query.radius_km * 1000);
    const rows = await this.database.query<ServiceLocationRow[]>(
      `SELECT id, source, type, name, address, phone, website, opening_hours,
              ST_X(location::geometry) AS longitude,
              ST_Y(location::geometry) AS latitude,
              is_verified, is_partner,
              ST_Distance(
                location,
                ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
              ) AS distance_meters
       FROM service_locations
       WHERE is_active = true
         AND ST_DWithin(
           location,
           ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
           $3
         )
         AND ($4::text[] IS NULL OR type::text = ANY($4::text[]))
       ORDER BY distance_meters ASC, id ASC
       LIMIT $5`,
      [query.longitude, query.latitude, radiusMeters, query.types ?? null, query.limit],
    );
    return rows.map((row) => this.present(row));
  }

  private present(row: ServiceLocationRow) {
    return {
      id: row.id,
      source: row.source,
      type: row.type,
      name: row.name,
      address: row.address,
      phone: row.phone,
      website: row.website,
      openingHours: row.opening_hours,
      latitude: Number(row.latitude),
      longitude: Number(row.longitude),
      isVerified: row.is_verified,
      isPartner: row.is_partner,
      ...(row.distance_meters === undefined ? {} : {
        distanceMeters: row.distance_meters === null ? null : Math.round(Number(row.distance_meters)),
      }),
    };
  }
}
