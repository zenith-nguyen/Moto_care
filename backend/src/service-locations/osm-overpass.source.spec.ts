import { mapOsmElement } from './osm-overpass.source';
import { ServiceLocationSource, ServiceLocationType } from './service-location-type.enum';

describe('OSM service-location mapper', () => {
  it('maps a named charging station and preserves source identity', () => {
    expect(mapOsmElement({
      type: 'node',
      id: 123,
      lat: 10.7769,
      lon: 106.7009,
      timestamp: '2026-10-01T00:00:00Z',
      tags: {
        amenity: 'charging_station',
        name: 'Trạm sạc trung tâm',
        'addr:street': 'Lê Lợi',
        'addr:housenumber': '1',
      },
    })).toMatchObject({
      source: ServiceLocationSource.OSM,
      sourceId: 'node/123',
      type: ServiceLocationType.CHARGING_STATION,
      name: 'Trạm sạc trung tâm',
      address: '1 Lê Lợi',
      location: { type: 'Point', coordinates: [106.7009, 10.7769] },
      isVerified: false,
      isPartner: false,
    });
  });

  it('uses way centers and skips unnamed or unsupported elements', () => {
    expect(mapOsmElement({
      type: 'way',
      id: 456,
      center: { lat: 10.8, lon: 106.7 },
      tags: { shop: 'motorcycle_repair', name: 'Tiệm sửa xe A' },
    })).toMatchObject({ sourceId: 'way/456', type: ServiceLocationType.REPAIR_SHOP });
    expect(mapOsmElement({
      type: 'node', id: 1, lat: 10.8, lon: 106.7, tags: { amenity: 'fuel' },
    })).toBeNull();
    expect(mapOsmElement({
      type: 'node', id: 2, lat: 10.8, lon: 106.7, tags: { shop: 'bakery', name: 'Bakery' },
    })).toBeNull();
  });
});
