import 'package:flutter/foundation.dart';

enum RescueLocationSource { selected, device }

@immutable
class RescueLocation {
  const RescueLocation({
    required this.address,
    this.landmark = '',
    this.latitude,
    this.longitude,
    this.source = RescueLocationSource.selected,
  }) : assert((latitude == null) == (longitude == null)),
       assert(latitude == null || (latitude >= -90 && latitude <= 90)),
       assert(longitude == null || (longitude >= -180 && longitude <= 180));

  final String address;
  final String landmark;
  final double? latitude;
  final double? longitude;
  final RescueLocationSource source;

  bool get hasCoordinates => latitude != null && longitude != null;
}
