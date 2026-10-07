import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../home/models/rescue_location.dart';

final deviceLocationProvider = Provider<Future<RescueLocation> Function()>(
  (ref) => locateDevice,
);

Future<RescueLocation> locateDevice() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationLookupException('Hãy bật GPS hoặc nhập địa chỉ sự cố.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever ||
      permission == LocationPermission.denied) {
    throw const LocationLookupException(
      'Chưa được cấp quyền vị trí. Bạn có thể nhập địa chỉ hoặc cấp quyền trong Cài đặt.',
    );
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    ),
  );
  var address =
      'GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  try {
    final places = GeocodingPlatformFactory.instance == null
        ? <Placemark>[]
        : await Geocoding()
              .placemarkFromCoordinates(position.latitude, position.longitude)
              .timeout(const Duration(seconds: 8));
    if (places.isNotEmpty) {
      final place = places.first;
      final parts = [
        place.street,
        place.subLocality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ];
      final resolved = parts
          .whereType<String>()
          .where((part) => part.trim().isNotEmpty)
          .toSet()
          .join(', ');
      if (resolved.isNotEmpty && resolved.length <= 240) address = resolved;
    }
  } on Exception {
    // Coordinates remain usable if the platform cannot reverse-geocode them.
  }
  return RescueLocation(
    address: address,
    latitude: position.latitude,
    longitude: position.longitude,
  );
}

class LocationLookupException implements Exception {
  const LocationLookupException(this.message);
  final String message;
}
