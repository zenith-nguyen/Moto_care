import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../rescue_station/models/rescue_station.dart';
import '../../rescue_station/providers/rescue_station_provider.dart';
import '../models/rescue_location.dart';

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
    if (address.length < 5 || address.length > 240 || landmark.length > 240) {
      return false;
    }
    if ((location.latitude == null) != (location.longitude == null) ||
        (location.latitude != null &&
            (!location.latitude!.isFinite || location.latitude!.abs() > 90)) ||
        (location.longitude != null &&
            (!location.longitude!.isFinite ||
                location.longitude!.abs() > 180))) {
      return false;
    }
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

double stationDistanceKm(RescueStation station, RescueLocation? location) {
  if (location == null || !location.hasCoordinates) return station.distanceKm;
  double radians(double value) => value * math.pi / 180;
  final deltaLat = radians(station.latitude - location.latitude!);
  final deltaLon = radians(station.longitude - location.longitude!);
  final a =
      math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(radians(location.latitude!)) *
          math.cos(radians(station.latitude)) *
          math.pow(math.sin(deltaLon / 2), 2);
  return 6371 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
}

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
