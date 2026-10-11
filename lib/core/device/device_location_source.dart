import 'package:geolocator/geolocator.dart';

import '../../features/orders/domain/geo_point.dart';

enum DeviceLocationFailureKind {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.kind, this.message);

  final DeviceLocationFailureKind kind;
  final String message;

  @override
  String toString() => 'DeviceLocationException($kind, $message)';
}

abstract interface class DeviceLocationSource {
  Future<GeoPoint> currentLocation();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

class GeolocatorDeviceLocationSource implements DeviceLocationSource {
  const GeolocatorDeviceLocationSource();

  @override
  Future<GeoPoint> currentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeviceLocationException(
        DeviceLocationFailureKind.serviceDisabled,
        'Location services are disabled.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        DeviceLocationFailureKind.permissionDeniedForever,
        'Location permission is permanently denied.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(
        DeviceLocationFailureKind.permissionDenied,
        'Location permission was denied.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on DeviceLocationException {
      rethrow;
    } catch (_) {
      throw const DeviceLocationException(
        DeviceLocationFailureKind.unavailable,
        'A current location could not be obtained.',
      );
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
