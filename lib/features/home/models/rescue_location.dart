import 'package:flutter/foundation.dart';

@immutable
class RescueLocation {
  const RescueLocation({
    required this.address,
    this.landmark = '',
    this.latitude,
    this.longitude,
  }) : assert((latitude == null) == (longitude == null)),
       assert(latitude == null || (latitude >= -90 && latitude <= 90)),
       assert(longitude == null || (longitude >= -180 && longitude <= 180));

  final String address;
  final String landmark;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;
}
