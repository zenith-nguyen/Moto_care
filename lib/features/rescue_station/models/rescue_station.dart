import 'package:flutter/foundation.dart';

enum StationType {
  partner('partner', 'Đối tác MotoCare'),
  officialDealer('official_dealer', 'Đại lý chính hãng'),
  mobileTeam('mobile_team', 'Đội cứu hộ lưu động');

  const StationType(this.value, this.label);
  final String value;
  final String label;

  static StationType fromValue(String value) => values.firstWhere(
    (type) => type.value == value,
    orElse: () => throw FormatException('Unknown station type: $value'),
  );
}

@immutable
class RescueStation {
  RescueStation({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.completedRescues,
    required this.distanceKm,
    required this.isOpen24h,
    required this.isVerified,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.stationType,
    this.isOpen = true,
    this.hasOperationalData = true,
    this.hasStatistics = true,
  }) {
    if (!rating.isFinite ||
        rating < 0 ||
        rating > 5 ||
        completedRescues < 0 ||
        !distanceKm.isFinite ||
        distanceKm < 0) {
      throw ArgumentError('Invalid rescue station statistics');
    }
    if (!latitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        !longitude.isFinite ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Invalid rescue station coordinates');
    }
    if (isOpen24h && !isOpen) {
      throw ArgumentError('A 24-hour station must be open');
    }
  }

  final String id;
  final String name;
  final String address;
  final double rating;
  final int completedRescues;
  final double distanceKm;
  final bool isOpen24h;
  final bool isVerified;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final StationType stationType;
  final bool isOpen;
  final bool hasOperationalData;
  final bool hasStatistics;

  factory RescueStation.fromServiceLocation(Map<String, dynamic> json) {
    final distanceMeters = (json['distanceMeters'] as num?)?.toDouble();
    final openingHours = (json['openingHours'] as String?)
        ?.trim()
        .toLowerCase();
    return RescueStation(
      id: 'service-location-${json['id']}',
      name: json['name'] as String,
      address: (json['address'] as String?)?.trim().isNotEmpty == true
          ? (json['address'] as String).trim()
          : 'Chưa có địa chỉ chi tiết',
      rating: 0,
      completedRescues: 0,
      distanceKm: distanceMeters == null ? 0 : distanceMeters / 1000,
      isOpen24h: openingHours == '24/7' || openingHours == '24 hours',
      isVerified: json['isVerified'] as bool? ?? false,
      phoneNumber: (json['phone'] as String?)?.trim() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      stationType: StationType.partner,
      hasOperationalData: openingHours != null && openingHours.isNotEmpty,
      hasStatistics: false,
    );
  }

  factory RescueStation.fromJson(Map<String, dynamic> json) => RescueStation(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    rating: (json['rating'] as num).toDouble(),
    completedRescues: (json['completedRescues'] as num).toInt(),
    distanceKm: (json['distanceKm'] as num).toDouble(),
    isOpen24h: json['isOpen24h'] as bool,
    isVerified: json['isVerified'] as bool,
    phoneNumber: json['phoneNumber'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    stationType: StationType.fromValue(json['stationType'] as String),
    isOpen: json['isOpen'] as bool? ?? true,
    hasOperationalData: json['hasOperationalData'] as bool? ?? true,
    hasStatistics: json['hasStatistics'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'rating': rating,
    'completedRescues': completedRescues,
    'distanceKm': distanceKm,
    'isOpen24h': isOpen24h,
    'isVerified': isVerified,
    'phoneNumber': phoneNumber,
    'latitude': latitude,
    'longitude': longitude,
    'stationType': stationType.value,
    'isOpen': isOpen,
    'hasOperationalData': hasOperationalData,
    'hasStatistics': hasStatistics,
  };
}
