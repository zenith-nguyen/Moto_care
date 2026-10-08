import 'dart:math' as math;

import '../../home/models/rescue_location.dart';
import '../../rescue_station/models/rescue_station.dart';

class LocationService {
  const LocationService();
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
}
