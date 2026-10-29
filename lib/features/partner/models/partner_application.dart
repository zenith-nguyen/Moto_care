import 'dart:typed_data';

class PartnerApplication {
  PartnerApplication({
    required this.fullName,
    required this.citizenId,
    required Uint8List frontPhoto,
    required Uint8List backPhoto,
    required this.experience,
    required Set<String> tools,
    required this.district,
  }) : frontPhoto = Uint8List.fromList(frontPhoto).asUnmodifiableView(),
       backPhoto = Uint8List.fromList(backPhoto).asUnmodifiableView(),
       tools = Set.unmodifiable(tools);

  final String fullName;
  final String citizenId;
  final Uint8List frontPhoto;
  final Uint8List backPhoto;
  final String experience;
  final Set<String> tools;
  final String district;
}
