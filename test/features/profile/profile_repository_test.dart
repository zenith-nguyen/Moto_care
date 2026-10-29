import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/profile/data/profile_repository.dart';

import '../../support/recording_json_api.dart';

void main() {
  test('loads every persisted customer profile field', () async {
    final api = RecordingJsonApi()..objectResponse = _profileJson();

    final profile = await HttpProfileRepository(api).fetch();

    expect(api.lastMethod, 'GET');
    expect(api.lastPath, '/users/me');
    expect(profile.fullName, 'Zenith');
    expect(profile.emergencyContactName, 'Than');
    expect(profile.emergencyContactPhone, '0912345678');
    expect(profile.medicalNote, 'Di ung thuoc A');
    expect(profile.defaultAddress, 'Quan 1, TP.HCM');
    expect(profile.workAddress, 'Quan 3, TP.HCM');
  });

  test(
    'trims and sends editable details to the authenticated profile API',
    () async {
      final api = RecordingJsonApi()..objectResponse = _profileJson();

      await HttpProfileRepository(api).update(
        fullName: '  Zenith  ',
        phoneNumber: ' 0367518550 ',
        emergencyContactName: ' Than ',
        emergencyContactPhone: ' 0912345678 ',
        medicalNote: ' Di ung thuoc A ',
        homeAddress: ' Quan 1, TP.HCM ',
        workAddress: ' Quan 3, TP.HCM ',
      );

      expect(api.lastMethod, 'PATCH');
      expect(api.lastPath, '/users/me');
      expect(api.lastData, {
        'name': 'Zenith',
        'phone': '0367518550',
        'emergencyContactName': 'Than',
        'emergencyContactPhone': '0912345678',
        'medicalNote': 'Di ung thuoc A',
        'homeAddress': 'Quan 1, TP.HCM',
        'workAddress': 'Quan 3, TP.HCM',
      });
    },
  );
}

Map<String, dynamic> _profileJson() => {
  'id': 7,
  'name': 'Zenith',
  'email': 'zenith@example.com',
  'phone': '0367518550',
  'emergencyContactName': 'Than',
  'emergencyContactPhone': '0912345678',
  'medicalNote': 'Di ung thuoc A',
  'homeAddress': 'Quan 1, TP.HCM',
  'workAddress': 'Quan 3, TP.HCM',
  'role': 'CUSTOMER',
  'status': 'ACTIVE',
};
