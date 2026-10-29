import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/features/home/models/rescue_location.dart';
import 'package:moto_care/features/home/providers/home_provider.dart';
import 'package:moto_care/features/rescue_station/data/service_locations_repository.dart';
import 'package:moto_care/features/rescue_station/models/rescue_station.dart';
import 'package:moto_care/features/rescue_station/providers/rescue_station_provider.dart';

final _hcmStation = RescueStation(
  id: 'hcm-1',
  name: 'Tram cuu ho Quan 10',
  address: 'Quan 10, TP.HCM',
  rating: 0,
  completedRescues: 0,
  distanceKm: 1,
  isOpen24h: false,
  isVerified: true,
  phoneNumber: '',
  latitude: 10.77,
  longitude: 106.67,
  stationType: StationType.partner,
);

class _Repository implements ServiceLocationsRepository {
  int nearbyCalls = 0;
  int hcmCalls = 0;
  List<RescueStation> nearbyResult = const [];

  @override
  Future<List<RescueStation>> nearby({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) async {
    nearbyCalls++;
    return nearbyResult;
  }

  @override
  Future<List<RescueStation>> hoChiMinhCity() async {
    hcmCalls++;
    return [_hcmStation];
  }
}

void main() {
  test(
    'foreign emulator GPS is ignored and TP.HCM stations are returned',
    () async {
      final repository = _Repository();
      final container = ProviderContainer(
        overrides: [
          runtimeApiIntegrationProvider.overrideWithValue(true),
          serviceLocationsRepositoryProvider.overrideWithValue(repository),
          initialRescueLocationProvider.overrideWithValue(
            const RescueLocation(
              address: 'Googleplex, California',
              latitude: 37.427204,
              longitude: -122.083996,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final stations = await container.read(rescueStationsAsyncProvider.future);

      expect(stations.single.id, _hcmStation.id);
      expect(repository.nearbyCalls, 0);
      expect(repository.hcmCalls, 1);
    },
  );

  test('empty nearby result falls back to the TP.HCM catalog', () async {
    final repository = _Repository();
    final container = ProviderContainer(
      overrides: [
        runtimeApiIntegrationProvider.overrideWithValue(true),
        serviceLocationsRepositoryProvider.overrideWithValue(repository),
        initialRescueLocationProvider.overrideWithValue(
          const RescueLocation(
            address: '191 Nguyen Tieu La, Quan 10, TP.HCM',
            latitude: 10.768,
            longitude: 106.668,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final stations = await container.read(rescueStationsAsyncProvider.future);

    expect(stations.single.id, _hcmStation.id);
    expect(repository.nearbyCalls, 1);
    expect(repository.hcmCalls, 1);
  });
}
