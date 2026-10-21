class ProfessionalProfile {
  const ProfessionalProfile({
    required this.bio,
    required this.yearsOfExperience,
    required this.serviceRadiusKm,
    required this.tier,
    required this.skills,
  });

  final String bio;
  final int yearsOfExperience;
  final double serviceRadiusKm;
  final String tier;
  final List<String> skills;

  factory ProfessionalProfile.fromJson(Map<String, dynamic> json) =>
      ProfessionalProfile(
        bio: json['bio'] as String? ?? '',
        yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt() ?? 0,
        serviceRadiusKm:
            double.tryParse('${json['serviceRadiusKm'] ?? 10}') ?? 10,
        tier: json['tier'] as String? ?? '',
        skills: [
          for (final item in (json['skills'] as List<dynamic>? ?? const []))
            if (item is Map<String, dynamic>) item['name'] as String? ?? '',
        ],
      );
}
