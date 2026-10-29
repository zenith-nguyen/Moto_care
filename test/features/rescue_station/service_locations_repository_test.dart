import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/rescue_station/data/service_locations_repository.dart';

import '../../support/recording_json_api.dart';

void main() {
  test(
    'maps nearby PostGIS markers without inventing ratings or jobs',
    () async {
      final api = RecordingJsonApi()
        ..listResponse = [
          {
            'id': 12,
            'source': 'OSM',
            'type': 'REPAIR_SHOP',
            'name': 'Tiệm sửa xe thật',
            'address': 'Quận 5, TP.HCM',
            'phone': '0900000000',
            'openingHours': null,
            'latitude': 10.757,
            'longitude': 106.668,
            'isVerified': false,
            'isPartner': false,
            'distanceMeters': 1250,
          },
        ];

      final stations = await HttpServiceLocationsRepository(api)
          .nearby(latitude: 10.77, longitude: 106.67);

      expect(api.lastPath, '/service-locations/nearby');
      expect(stations.single.name, 'Tiệm sửa xe thật');
      expect(stations.single.distanceKm, 1.25);
      expect(stations.single.hasStatistics, isFalse);
      expect(stations.single.hasOperationalData, isFalse);
    },
  );
}
