import '../../../core/network/json_api.dart';
import '../models/rescue_station.dart';

abstract interface class ServiceLocationsRepository {
  Future<List<RescueStation>> nearby({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  });

  Future<List<RescueStation>> hoChiMinhCity();
}

class HttpServiceLocationsRepository implements ServiceLocationsRepository {
  const HttpServiceLocationsRepository(this._api);

  final JsonApi _api;

  static const _supportedTypes = [
    'REPAIR_SHOP',
    'CHARGING_STATION',
    'FUEL_STATION',
    'PARTS_STORE',
  ];

  @override
  Future<List<RescueStation>> nearby({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) async {
    final rows = await _api.getList(
      '/service-locations/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        'limit': 100,
        'types': _supportedTypes,
      },
    );
    return List.unmodifiable(rows.map(RescueStation.fromServiceLocation));
  }

  @override
  Future<List<RescueStation>> hoChiMinhCity() async {
    final rows = await _api.getList(
      '/service-locations/nearby',
      queryParameters: {
        'latitude': 10.7769,
        'longitude': 106.7009,
        'radius_km': 50,
        'limit': 100,
        'types': _supportedTypes,
      },
    );
    return List.unmodifiable(rows.map(RescueStation.fromServiceLocation));
  }
}
