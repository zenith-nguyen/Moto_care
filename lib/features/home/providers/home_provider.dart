import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rescue_station/models/rescue_station.dart';
import '../../rescue_station/providers/rescue_station_provider.dart';
import '../models/rescue_location.dart';
import '../../location/services/location_validation.dart';
import '../../location/services/location_service.dart';

/// Supply an address and coordinates from the location service when available.
final initialRescueLocationProvider = Provider<RescueLocation?>((ref) => null);
final rescueLocationProvider =
    NotifierProvider<RescueLocationController, RescueLocation?>(
      RescueLocationController.new,
    );

class RescueLocationController extends Notifier<RescueLocation?> {
  @override
  RescueLocation? build() => ref.watch(initialRescueLocationProvider);

  bool confirmLocation(RescueLocation location) {
    final address = location.address.trim();
    final landmark = location.landmark.trim();
    if (!isValidRescueLocation(location)) return false;
    state = RescueLocation(
      address: address,
      landmark: landmark,
      latitude: location.latitude,
      longitude: location.longitude,
    );
    return true;
  }

  bool updateAddress(String address) {
    final value = address.trim();
    if (value.length < 5 || value.length > 240) return false;
    if (value == state?.address) return true;
    // A typed address must not retain coordinates from a different location.
    state = RescueLocation(address: value);
    return true;
  }
}

double stationDistanceKm(RescueStation station, RescueLocation? location) =>
    const LocationService().stationDistanceKm(station, location);

final homeNearbyStationsProvider = Provider<List<RescueStation>>((ref) {
  final location = ref.watch(rescueLocationProvider);
  final stations = [...ref.watch(rescueStationsProvider)];
  stations.sort((a, b) {
    final comparison = stationDistanceKm(
      a,
      location,
    ).compareTo(stationDistanceKm(b, location));
    return comparison == 0 ? a.id.compareTo(b.id) : comparison;
  });
  return List.unmodifiable(stations.take(6));
});

final stationDistanceProvider = Provider.family<double, RescueStation>(
  (ref, station) =>
      stationDistanceKm(station, ref.watch(rescueLocationProvider)),
);
