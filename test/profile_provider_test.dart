import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/profile/models/profile_validation.dart';
import 'package:moto_care/features/profile/models/user_profile.dart';
import 'package:moto_care/features/profile/providers/profile_provider.dart';

import 'fixtures/user_profile_fixture.dart';

void main() {
  test(
    'Profile JSON roundtrip retains emergency, vehicle and address data',
    () {
      final json = {
        ...profileFixture.toJson(),
        'avatarUrl': 'https://example.com/avatar.jpg',
      };
      final decoded = UserProfile.fromJson(json);
      expect(decoded.toJson(), json);
      final minimal = UserProfile.fromJson({'id': '1', 'fullName': 'An'});
      expect(minimal.defaultVehicle, isNull);
      expect(minimal.emergencyContactPhone, isEmpty);
      expect(minimal.memberTier, 'Chưa có hạng');
      expect(minimal.rewardPoints, 0);
    },
  );

  test('Phone validation normalizes Vietnamese numbers and rejects malformed input', () {
    expect(ProfileValidation.normalizePhone('+84 (900) 000-001'), '0900000001');
    expect(ProfileValidation.phone('+84 (900) 000-001'), isNull);
    expect(ProfileValidation.phone('02812345678'), isNull);
    for (final phone in [
      '',
      '123',
      '09000000001',
      'abc0900000001',
      '+10900000001',
    ]) {
      expect(ProfileValidation.phone(phone), isNotNull);
    }
    expect(ProfileValidation.phone('', optional: true), isNull);
  });

  test(
    'Edits persist for the same identity and preserve membership and vehicle',
    () {
      final container = ProviderContainer(
        overrides: [
          initialUserProfileProvider.overrideWithValue(profileFixture),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(profileProvider.notifier);
      expect(
        controller.saveDetails(
          fullName: '  Nguyễn An  ',
          phoneNumber: '+84 900 000 003',
          emergencyContactName: ' Mẹ ',
          emergencyContactPhone: '',
          medicalNote: ' Lưu ý ',
        ),
        isTrue,
      );
      controller.initialize(
        const UserProfile(id: 'member-001', fullName: 'Old name'),
      );
      final edited = container.read(profileProvider).profile;
      expect(edited.fullName, 'Nguyễn An');
      expect(edited.phoneNumber, '0900000003');
      expect(edited.emergencyContactPhone, isEmpty);
      expect(edited.medicalNote, 'Lưu ý');
      expect(edited.defaultVehicle, same(profileFixture.defaultVehicle));
      expect(edited.email, profileFixture.email);
      expect(edited.memberTier, profileFixture.memberTier);
      expect(edited.rewardPoints, profileFixture.rewardPoints);
    },
  );

  test('Invalid edits never replace existing profile', () {
    final container = ProviderContainer(
      overrides: [initialUserProfileProvider.overrideWithValue(profileFixture)],
    );
    addTearDown(container.dispose);
    final controller = container.read(profileProvider.notifier);
    expect(
      controller.saveDetails(
        fullName: '',
        phoneNumber: '123',
        emergencyContactName: '',
        emergencyContactPhone: '12',
        medicalNote: '',
      ),
      isFalse,
    );
    expect(container.read(profileProvider).profile, same(profileFixture));
  });

  test('New account clears the previous avatar and biometric preference', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(profileProvider.notifier);
    controller.initialize(profileFixture);
    final input = Uint8List.fromList([1, 2, 3]);
    controller.setAvatar(input);
    input[0] = 9;
    expect(container.read(profileProvider).avatarBytes!.first, 1);
    expect(
      () => container.read(profileProvider).avatarBytes![0] = 8,
      throwsUnsupportedError,
    );
    controller.setBiometricEnabled(true);
    controller.initialize(
      const UserProfile(id: 'member-002', fullName: 'Bình'),
    );
    final state = container.read(profileProvider);
    expect(state.profile.fullName, 'Bình');
    expect(state.avatarBytes, isNull);
    expect(state.biometricEnabled, isFalse);
  });

  test('Ending the session clears all local profile data', () {
    final container = ProviderContainer(
      overrides: [initialUserProfileProvider.overrideWithValue(profileFixture)],
    );
    addTearDown(container.dispose);
    final controller = container.read(profileProvider.notifier);
    controller.setBiometricEnabled(true);
    controller.setAvatar(Uint8List.fromList([1]));
    controller.clearSession();
    final state = container.read(profileProvider);
    expect(state.profile, UserProfile.empty);
    expect(state.initialized, isFalse);
    expect(state.avatarBytes, isNull);
    expect(state.biometricEnabled, isFalse);
  });
}
