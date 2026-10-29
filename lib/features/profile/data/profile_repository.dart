import '../../../core/network/json_api.dart';
import '../models/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> fetch();

  Future<UserProfile> update({
    required String fullName,
    required String phoneNumber,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String medicalNote,
    String? homeAddress,
    String? workAddress,
  });
}

class HttpProfileRepository implements ProfileRepository {
  const HttpProfileRepository(this._api);

  final JsonApi _api;

  @override
  Future<UserProfile> fetch() async =>
      UserProfile.fromApiJson(await _api.getObject('/users/me'));

  @override
  Future<UserProfile> update({
    required String fullName,
    required String phoneNumber,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String medicalNote,
    String? homeAddress,
    String? workAddress,
  }) async {
    final json = await _api.patchObject(
      '/users/me',
      data: {
        'name': fullName.trim(),
        'phone': phoneNumber.trim(),
        'emergencyContactName': emergencyContactName.trim(),
        'emergencyContactPhone': emergencyContactPhone.trim(),
        'medicalNote': medicalNote.trim(),
        if (homeAddress != null) 'homeAddress': homeAddress.trim(),
        if (workAddress != null) 'workAddress': workAddress.trim(),
      },
    );
    return UserProfile.fromApiJson(json);
  }
}
