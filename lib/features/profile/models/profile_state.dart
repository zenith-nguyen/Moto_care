import 'package:flutter/foundation.dart';

import 'user_profile.dart';

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
