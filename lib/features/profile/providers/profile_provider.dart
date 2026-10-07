import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile_validation.dart';
import '../models/user_profile.dart';

/// Override with account data when the authentication API is connected.
final initialUserProfileProvider = Provider<UserProfile>(
  (ref) => UserProfile.empty,
);

final profileProvider = NotifierProvider<ProfileController, ProfileState>(
  ProfileController.new,
);

@immutable
class ProfileState {
  const ProfileState({
    required this.profile,
    this.initialized = false,
    this.avatarBytes,
    this.biometricEnabled = false,
  });

  final UserProfile profile;
  final bool initialized;
  final Uint8List? avatarBytes;
  final bool biometricEnabled;

  ProfileState copyWith({
    UserProfile? profile,
    bool? initialized,
    Uint8List? avatarBytes,
    bool? biometricEnabled,
  }) => ProfileState(
    profile: profile ?? this.profile,
    initialized: initialized ?? this.initialized,
    avatarBytes: avatarBytes ?? this.avatarBytes,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
  );
}

class ProfileController extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    final profile = ref.watch(initialUserProfileProvider);
    return ProfileState(
      profile: profile,
      initialized: profile != UserProfile.empty,
    );
  }

  void initialize(UserProfile seed) {
    if (state.initialized && state.profile.id == seed.id) return;
    // An API-supplied profile takes priority over the limited HomeUser payload.
    state = ProfileState(profile: seed, initialized: true);
  }

  bool saveDetails({
    required String fullName,
    required String phoneNumber,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String medicalNote,
  }) {
    if (ProfileValidation.fullName(fullName) != null ||
        ProfileValidation.phone(phoneNumber) != null ||
        ProfileValidation.phone(emergencyContactPhone, optional: true) !=
            null ||
        emergencyContactName.trim().length > 80 ||
        medicalNote.trim().length > 240) {
      return false;
    }
    state = state.copyWith(
      profile: state.profile.copyWith(
        fullName: fullName.trim(),
        phoneNumber: ProfileValidation.normalizePhone(phoneNumber),
        emergencyContactName: emergencyContactName.trim(),
        emergencyContactPhone: ProfileValidation.normalizePhone(
          emergencyContactPhone,
        ),
        medicalNote: medicalNote.trim(),
      ),
    );
    return true;
  }

  void setAvatar(Uint8List bytes) {
    state = state.copyWith(
      avatarBytes: Uint8List.fromList(bytes).asUnmodifiableView(),
    );
  }

  void setBiometricEnabled(bool enabled) {
    state = state.copyWith(biometricEnabled: enabled);
  }

  void clearSession() => state = const ProfileState(profile: UserProfile.empty);
}
