import 'package:flutter/foundation.dart';

@immutable
class ProfileVehicle {
  const ProfileVehicle({
    required this.type,
    required this.plate,
    required this.tireType,
  });

  final String type;
  final String plate;
  final String tireType;

  factory ProfileVehicle.fromJson(Map<String, dynamic> json) => ProfileVehicle(
    type: json['type'] as String,
    plate: json['plate'] as String,
    tireType: json['tireType'] as String,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'plate': plate,
    'tireType': tireType,
  };
}

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    this.phoneNumber = '',
    this.email = '',
    this.avatarUrl,
    this.memberTier = 'Chưa có hạng',
    this.rewardPoints = 0,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.defaultVehicle,
    this.defaultAddress = '',
    this.workAddress = '',
    this.medicalNote = '',
  });

  static const empty = UserProfile(id: '', fullName: '');

  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String? avatarUrl;
  final String memberTier;
  final int rewardPoints;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final ProfileVehicle? defaultVehicle;
  final String defaultAddress;
  final String workAddress;
  final String medicalNote;

  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? medicalNote,
  }) => UserProfile(
    id: id,
    fullName: fullName ?? this.fullName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    email: email,
    avatarUrl: avatarUrl,
    memberTier: memberTier,
    rewardPoints: rewardPoints,
    emergencyContactName: emergencyContactName ?? this.emergencyContactName,
    emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    defaultVehicle: defaultVehicle,
    defaultAddress: defaultAddress,
    workAddress: workAddress,
    medicalNote: medicalNote ?? this.medicalNote,
  );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    phoneNumber: json['phoneNumber'] as String? ?? '',
    email: json['email'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    memberTier: json['memberTier'] as String? ?? 'Chưa có hạng',
    rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
    emergencyContactName: json['emergencyContactName'] as String? ?? '',
    emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
    defaultVehicle: json['defaultVehicle'] == null
        ? null
        : ProfileVehicle.fromJson(
            json['defaultVehicle'] as Map<String, dynamic>,
          ),
    defaultAddress: json['defaultAddress'] as String? ?? '',
    workAddress: json['workAddress'] as String? ?? '',
    medicalNote: json['medicalNote'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'email': email,
    'avatarUrl': avatarUrl,
    'memberTier': memberTier,
    'rewardPoints': rewardPoints,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'defaultVehicle': defaultVehicle?.toJson(),
    'defaultAddress': defaultAddress,
    'workAddress': workAddress,
    'medicalNote': medicalNote,
  };
}
