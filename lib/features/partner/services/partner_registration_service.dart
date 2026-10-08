import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/partner_application.dart';

class PartnerRegistrationOptions {
  const PartnerRegistrationOptions({
    this.experience = const [
      'Dưới 1 năm',
      '1 - 3 năm',
      '3 - 5 năm',
      'Trên 5 năm',
    ],
    this.tools = const [
      'Bơm điện',
      'Bộ vá lốp',
      'Bình ắc quy phụ',
      'Bộ chìa khóa',
    ],
    this.districts = const [
      'Quận 1',
      'Quận 3',
      'Quận 7',
      'Bình Thạnh',
      'Tân Bình',
      'Thủ Đức',
      'Bình Chánh',
      'Hóc Môn',
    ],
  });
  final List<String> experience, tools, districts;
}

final partnerRegistrationOptionsProvider = Provider<PartnerRegistrationOptions>(
  (ref) => const PartnerRegistrationOptions(),
);
final partnerRegistrationServiceProvider = Provider<PartnerRegistrationService>(
  (ref) => const PartnerRegistrationService(),
);

class PartnerRegistrationService {
  const PartnerRegistrationService();
  String? validateName(String? value) =>
      (value?.trim().length ?? 0) < 2 ? 'Vui lòng nhập họ tên đầy đủ.' : null;
  String? validateCitizenId(String? value) =>
      RegExp(r'^\d{12}$').hasMatch(value ?? '')
      ? null
      : 'Số CCCD phải gồm 12 chữ số.';
  String? validateExperience(String? value) =>
      value == null ? 'Vui lòng chọn số năm kinh nghiệm.' : null;
  String? validateDistrict(String? value) =>
      value == null ? 'Vui lòng chọn khu vực hoạt động.' : null;
  PartnerApplication create({
    required String fullName,
    required String citizenId,
    required Uint8List? front,
    required Uint8List? back,
    required String? experience,
    required Set<String> tools,
    required String? district,
  }) {
    if (validateName(fullName) != null ||
        validateCitizenId(citizenId) != null ||
        front == null ||
        back == null ||
        experience == null ||
        tools.isEmpty ||
        district == null) {
      throw ArgumentError('Incomplete partner application');
    }
    return PartnerApplication(
      fullName: fullName.trim(),
      citizenId: citizenId.trim(),
      frontPhoto: front,
      backPhoto: back,
      experience: experience,
      tools: tools,
      district: district,
    );
  }
}
