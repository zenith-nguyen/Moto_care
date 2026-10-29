import 'package:geolocator/geolocator.dart';

import 'location_fix_validation.dart';
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
        'GPS đang tắt. Hãy bật vị trí trên thiết bị.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        DeviceLocationFailureKind.permissionDeniedForever,
        'Quyền vị trí đã bị từ chối. Hãy cấp quyền trong Cài đặt.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(
        DeviceLocationFailureKind.permissionDenied,
        'Ứng dụng chưa được cấp quyền vị trí.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!isRecentLocationFix(position.timestamp, DateTime.now()) ||
          !isInHoChiMinhCity(position.latitude, position.longitude)) {
        throw const DeviceLocationException(
          DeviceLocationFailureKind.unavailable,
          'GPS cũ hoặc ngoài vùng phục vụ TP.HCM. Nếu dùng máy ảo, hãy đặt lại Location.',
        );
      }
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on DeviceLocationException {
      rethrow;
    } catch (_) {
      throw const DeviceLocationException(
        DeviceLocationFailureKind.unavailable,
        'Chưa lấy được vị trí hiện tại. Hãy thử lại.',
      );
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
