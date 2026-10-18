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
  if (!isHoChiMinhCityServiceArea(position.latitude, position.longitude)) {
    throw const LocationLookupException(
      'GPS hiện nằm ngoài vùng phục vụ TP.HCM. Nếu đang dùng máy ảo, hãy đặt Location về TP.HCM hoặc nhập địa chỉ Nhà/Cơ quan.',
    );
  }
  var address =
      'GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  List<Placemark> places;
  try {
    places = GeocodingPlatformFactory.instance == null
        ? <Placemark>[]
        : await Geocoding()
              .placemarkFromCoordinates(position.latitude, position.longitude)
              .timeout(const Duration(seconds: 8));
  } on Exception {
    throw const LocationLookupException(
      'Chưa xác minh được GPS thuộc Việt Nam. Hãy thử lại hoặc nhập địa chỉ Nhà/Cơ quan.',
    );
  }
  if (places.isEmpty || !isVietnamPlacemark(places.first)) {
    throw const LocationLookupException(
      'GPS không thuộc Việt Nam hoặc chưa xác minh được quốc gia. Vị trí này sẽ không được sử dụng.',
    );
  }
  final place = places.first;
  final parts = [
    place.street,
    place.subLocality,
    place.subAdministrativeArea,
    place.administrativeArea,
    place.country,
  ];
  final resolved = parts
      .whereType<String>()
      .where((part) => part.trim().isNotEmpty)
      .toSet()
      .join(', ');
  if (resolved.isNotEmpty && resolved.length <= 240) address = resolved;
  return RescueLocation(
    address: address,
    latitude: position.latitude,
    longitude: position.longitude,
  );
}

bool isHoChiMinhCityServiceArea(double latitude, double longitude) =>
    latitude >= 10.30 &&
    latitude <= 11.25 &&
    longitude >= 106.30 &&
    longitude <= 107.15;

bool isVietnamPlacemark(Placemark place) {
  final code = place.isoCountryCode?.trim().toUpperCase();
  if (code == 'VN') return true;
  final country = place.country?.trim().toLowerCase();
  return country == 'việt nam' || country == 'viet nam' || country == 'vietnam';
}

class LocationLookupException implements Exception {
  const LocationLookupException(this.message);
  final String message;
}
