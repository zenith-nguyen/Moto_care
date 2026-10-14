import 'dart:typed_data';

class PartnerRegistrationDraft {
  PartnerRegistrationDraft({
    this.step = 0,
    this.experience,
    this.district,
    Set<String> tools = const {},
    this.front,
    this.back,
    this.showToolError = false,
    this.submitted = false,
  }) : tools = Set.unmodifiable(tools);
  final int step;
  final String? experience, district;
  final Set<String> tools;
  final Uint8List? front, back;
  final bool showToolError, submitted;
}
