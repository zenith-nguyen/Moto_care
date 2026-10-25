import '../../../core/network/json_api.dart';
import '../../../core/network/json_reader.dart';

/// Review state of a customer's provider application. `none` means the account
/// has never applied.
enum ProviderApplicationStatus {
  none('NONE'),
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  const ProviderApplicationStatus(this.wire);
  final String wire;

  static ProviderApplicationStatus parse(Object? value) {
    final text = value?.toString();
    for (final status in values) {
      if (status.wire == text) return status;
    }
    return ProviderApplicationStatus.none;
  }
}

class ProviderApplication {
  const ProviderApplication({
    required this.status,
    this.bio,
    this.documentUrl,
    this.yearsOfExperience,
    this.serviceRadiusKm,
  });

  final ProviderApplicationStatus status;
  final String? bio;
  final String? documentUrl;
  final int? yearsOfExperience;
  final double? serviceRadiusKm;

  factory ProviderApplication.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final status = ProviderApplicationStatus.parse(json['approvalStatus']);
    if (status == ProviderApplicationStatus.none) {
      return const ProviderApplication(status: ProviderApplicationStatus.none);
    }
    return ProviderApplication(
      status: status,
      bio: json['bio'] as String?,
      documentUrl: json['documentUrl'] as String?,
      yearsOfExperience: json['yearsOfExperience'] == null
          ? null
          : reader.number('yearsOfExperience').toInt(),
      serviceRadiusKm: json['serviceRadiusKm'] == null
          ? null
          : reader.number('serviceRadiusKm').toDouble(),
    );
  }
}

class ProviderApplicationInput {
  const ProviderApplicationInput({
    this.bio,
    this.documentUrl,
    this.yearsOfExperience,
    this.serviceRadiusKm,
  });

  final String? bio;
  final String? documentUrl;
  final int? yearsOfExperience;
  final double? serviceRadiusKm;

  Map<String, dynamic> toJson() => {
    if (bio != null && bio!.trim().isNotEmpty) 'bio': bio!.trim(),
    if (documentUrl != null && documentUrl!.trim().isNotEmpty)
      'documentUrl': documentUrl!.trim(),
    if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
    if (serviceRadiusKm != null) 'serviceRadiusKm': serviceRadiusKm,
  };
}

abstract interface class ProviderApplicationRepository {
  Future<ProviderApplication> mine();

  Future<ProviderApplication> submit(ProviderApplicationInput input);
}

class HttpProviderApplicationRepository
    implements ProviderApplicationRepository {
  const HttpProviderApplicationRepository(this._api);

  final JsonApi _api;

  @override
  Future<ProviderApplication> mine() async {
    final response = await _api.getObject('/provider-applications/me');
    return ProviderApplication.fromJson(response);
  }

  @override
  Future<ProviderApplication> submit(ProviderApplicationInput input) async {
    final response = await _api.postObject(
      '/provider-applications',
      data: input.toJson(),
    );
    return ProviderApplication.fromJson(response);
  }
}
