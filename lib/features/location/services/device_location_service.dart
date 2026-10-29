import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/device/location_fix_validation.dart';
import '../../home/models/rescue_location.dart';

final deviceLocationProvider = Provider<Future<RescueLocation> Function()>(
  (ref) => locateDevice,
);

final deviceAddressGeocoderProvider =
    Provider<Future<RescueLocation> Function(String)>(
      (ref) => geocodeDeviceAddress,
    );

final deviceReverseGeocoderProvider =
    Provider<Future<RescueLocation> Function(double, double)>(
      (ref) => reverseGeocodeDevicePoint,
    );

Future<RescueLocation> geocodeDeviceAddress(String address) async {
  final normalized = address.trim();
  if (normalized.length < 5) {
    throw const LocationLookupException(
      'Hãy nhập địa chỉ chi tiết hơn trước khi tìm trên bản đồ.',
    );
  }
  if (GeocodingPlatformFactory.instance == null) {
    throw const LocationLookupException(
      'Thiết bị chưa hỗ trợ tìm tọa độ từ địa chỉ. Hãy dùng GPS hoặc chọn trên bản đồ.',
    );
  }
  final query = _withHoChiMinhCity(normalized);
  try {
    final matches = await Geocoding()
        .locationFromAddress(query)
        .timeout(const Duration(seconds: 12));
    if (matches.isEmpty) {
      throw const LocationLookupException(
        'Không tìm thấy địa chỉ này. Hãy thêm số nhà, tên đường và quận.',
      );
    }
    final match = matches.firstWhere(
      (item) => isHoChiMinhCityServiceArea(item.latitude, item.longitude),
      orElse: () => throw const LocationLookupException(
        'Địa chỉ không nằm trong vùng phục vụ TP.HCM.',
      ),
    );
    return RescueLocation(
      address: normalized,
      latitude: match.latitude,
      longitude: match.longitude,
    );
  } on LocationLookupException {
    rethrow;
  } on Exception {
    throw const LocationLookupException(
      'Chưa tìm được tọa độ địa chỉ. Hãy thử thêm quận hoặc chọn trực tiếp trên bản đồ.',
    );
  }
}

Future<RescueLocation> reverseGeocodeDevicePoint(
  double latitude,
  double longitude,
) async {
  if (!isHoChiMinhCityServiceArea(latitude, longitude)) {
    throw const LocationLookupException(
      'Vị trí không nằm trong vùng phục vụ TP.HCM.',
    );
  }
  if (GeocodingPlatformFactory.instance == null) {
    throw const LocationLookupException(
      'Thiết bị chưa hỗ trợ tra tên đường tại vị trí này.',
    );
  }
  try {
    final places = await Geocoding()
        .placemarkFromCoordinates(latitude, longitude)
        .timeout(const Duration(seconds: 10));
    if (places.isEmpty || !isVietnamPlacemark(places.first)) {
      throw const LocationLookupException(
        'Chưa xác minh được địa chỉ tại vị trí này.',
      );
    }
    final address = _placemarkAddress(places.first);
    if (address.isEmpty) {
      throw const LocationLookupException(
        'Chưa tra được tên đường tại vị trí này.',
      );
    }
    return RescueLocation(
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  } on LocationLookupException {
    rethrow;
  } on Exception {
    throw const LocationLookupException(
      'Chưa tra được tên đường. Vị trí ghim vẫn được giữ chính xác.',
    );
  }
}

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
  if (!isRecentLocationFix(position.timestamp, DateTime.now())) {
    throw const LocationLookupException(
      'GPS đang trả vị trí cũ. Nếu dùng máy ảo, hãy mở Location → Set location rồi thử lại.',
    );
  }
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
  final resolved = _placemarkAddress(places.first);
  if (resolved.isNotEmpty && resolved.length <= 240) address = resolved;
  return RescueLocation(
    address: address,
    latitude: position.latitude,
    longitude: position.longitude,
    source: RescueLocationSource.device,
  );
}

String _withHoChiMinhCity(String address) {
  final folded = address.toLowerCase();
  if (folded.contains('hồ chí minh') ||
      folded.contains('ho chi minh') ||
      folded.contains('tp.hcm') ||
      folded.contains('tphcm')) {
    return address;
  }
  return '$address, Thành phố Hồ Chí Minh, Việt Nam';
}

String _placemarkAddress(Placemark place) =>
    [
          place.street,
          place.subLocality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.country,
        ]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .join(', ');

bool isHoChiMinhCityServiceArea(double latitude, double longitude) =>
    isInHoChiMinhCity(latitude, longitude);

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
