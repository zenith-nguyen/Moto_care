import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/orders/domain/geo_point.dart';
import 'package:moto_care/features/providers/data/providers_repository.dart';

import '../../support/recording_json_api.dart';

void main() {
  test('updates waiting location before provider goes online', () async {
    final api = RecordingJsonApi()
      ..objectResponse = {
        'id': 3,
        'isOnline': false,
        'lastSeenAt': '2026-10-10T08:00:00.000Z',
      };
    final repository = HttpProvidersRepository(api);

    final presence = await repository.updateWaitingLocation(
      GeoPoint(latitude: 10.7769, longitude: 106.7009),
    );

    expect(api.lastMethod, 'PATCH');
    expect(api.lastPath, '/providers/me/location');
    expect(api.lastData, {'latitude': 10.7769, 'longitude': 106.7009});
    expect(presence.providerId, 3);
  });

  test('parses pending offers with pricing and GeoJSON location', () async {
    final api = RecordingJsonApi()
      ..listResponse = [
        {
          'id': 9,
          'orderId': 42,
          'expiresAt': '2099-10-10T08:00:15.000Z',
          'order': {
            'code': 'MC-42',
            'incidentType': {'id': 1, 'name': 'Flat tire'},
            'estimatedPrice': '110000.00',
            'pricing': _pricingJson(),
            'customerLocation': {
              'type': 'Point',
              'coordinates': [106.7009, 10.7769],
            },
          },
        },
      ];

    final offers = await HttpProvidersRepository(api).listPendingOffers();

    expect(api.lastPath, '/providers/me/offers/pending');
    expect(offers.single.order.estimatedPrice.value, '110000.00');
    expect(offers.single.order.customerLocation.longitude, 106.7009);
  });
}

Map<String, dynamic> _pricingJson() => {
  'basePrice': '100000.00',
  'weatherSurcharge': '10000.00',
  'weatherMultiplier': '1.1000',
  'weatherCategory': 'MODERATE',
  'weatherSource': 'OPEN_METEO',
  'weatherObservedAt': '2026-10-10T07:55:00.000Z',
  'weatherCode': 61,
  'precipitationMm': '1.20',
  'windSpeedKmh': '12.00',
  'windGustKmh': '20.00',
  'attribution': 'Weather data by Open-Meteo.com',
};
