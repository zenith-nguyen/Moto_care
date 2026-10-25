import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/services/search_service.dart';
import '../../home/providers/home_provider.dart';
import '../../location/services/device_location_service.dart';
import '../models/service_place.dart';
import '../data/demo_service_places.dart';

const _liveTypes = <String>[
  'REPAIR_SHOP',
  'CHARGING_STATION',
  'FUEL_STATION',
  'PARTS_STORE',
];

// Live charging stations / repair shops from GET /service-locations/nearby.
// Distance is real (relative to the user's GPS when available, otherwise to the
// HCMC centre). If the area returns nothing we fall back to the seed list so the
// screen is never empty. Offline/demo mode always shows the seed list.
final servicePlacesAsyncProvider =
    FutureProvider.autoDispose<List<ServicePlace>>((ref) async {
      if (!ref.watch(runtimeApiIntegrationProvider)) return demoServicePlaces;
      final api = ref.watch(jsonApiProvider);
      final location = ref.watch(rescueLocationProvider);
      var latitude = 10.7769;
      var longitude = 106.7009;
      var radiusKm = 50.0;
      if (location != null &&
          location.hasCoordinates &&
          isHoChiMinhCityServiceArea(location.latitude!, location.longitude!)) {
        latitude = location.latitude!;
        longitude = location.longitude!;
        radiusKm = 20;
      }
      final rows = await api.getList(
        '/service-locations/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
          'limit': 100,
          'types': _liveTypes,
        },
      );
      final places = rows.map(_toServicePlace).toList(growable: false);
      return places.isEmpty ? demoServicePlaces : List.unmodifiable(places);
    });

ServicePlace _toServicePlace(Map<String, dynamic> row) {
  final type = (row['type'] as String?)?.toUpperCase();
  final distanceMeters = (row['distanceMeters'] as num?)?.toDouble();
  final opening = (row['openingHours'] as String?)?.trim().toLowerCase();
  final phone = (row['phone'] as String?)?.trim();
  final address = (row['address'] as String?)?.trim();
  return ServicePlace(
    id: 'service-location-${row['id']}',
    name: row['name'] as String,
    address: address == null || address.isEmpty
        ? 'Chưa có địa chỉ chi tiết'
        : address,
    distanceKm: distanceMeters == null ? 0 : distanceMeters / 1000,
    rating: 0, // service locations have no rating in the backend yet
    isOpen: true,
    isCharging: type == 'CHARGING_STATION',
    is24Hours: opening == '24/7' || opening == '24 hours',
    repairsPetrol: type == 'REPAIR_SHOP',
    phone: phone == null || phone.isEmpty ? null : phone,
    latitude: (row['latitude'] as num?)?.toDouble(),
    longitude: (row['longitude'] as num?)?.toDouble(),
  );
}

// Synchronous view kept for callers that do not need the loading state: live
// data when it has resolved, otherwise the seed list.
final servicePlacesProvider = Provider<List<ServicePlace>>((ref) {
  if (!ref.watch(runtimeApiIntegrationProvider)) return demoServicePlaces;
  return ref.watch(servicePlacesAsyncProvider).value ?? const [];
});

List<ServicePlace> filterServicePlaces(
  List<ServicePlace> places,
  String query,
  Set<String> filters,
) {
  final result =
      places
          .where(
            (place) =>
                normalizeServiceSearch('${place.name} ${place.address}')
                    .contains(normalizeServiceSearch(query)) &&
                (!filters.contains('Trạm sạc') || place.isCharging) &&
                (!filters.contains('Mở 24/7') || place.is24Hours) &&
                (!filters.contains('Sửa xe xăng') || place.repairsPetrol),
          )
          .toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return List.unmodifiable(result);
}

final filteredServicePlacesProvider = Provider.autoDispose
    .family<List<ServicePlace>, (String, Set<String>)>((ref, selection) {
      return filterServicePlaces(
        ref.watch(servicePlacesProvider),
        selection.$1,
        selection.$2,
      );
    });
