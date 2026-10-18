import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../models/profile_validation.dart';
import '../models/user_profile.dart';
import '../models/profile_state.dart';
import '../../home/models/home_user.dart';
export '../models/profile_state.dart';

/// Override with account data when the authentication API is connected.
final initialUserProfileProvider = Provider<UserProfile>(
  (ref) => UserProfile.empty,
);

final profileProvider = NotifierProvider<ProfileController, ProfileState>(
  ProfileController.new,
);

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

  void initializeFromHome(HomeUser? user, {bool onlyIfUninitialized = false}) {
    if (onlyIfUninitialized && state.initialized) return;
    if (user == null && state.initialized) return;
    initialize(
      UserProfile(
        id: user?.memberId ?? '',
        fullName: user?.displayName.trim() ?? '',
        memberTier: user?.membershipLabel ?? 'Chưa có hạng',
        rewardPoints: user?.rewardPoints ?? 0,
      ),
    );
  }

  Future<void> refreshFromApi() async {
    if (!ref.read(runtimeApiIntegrationProvider)) return;
    final remote = await ref.read(profileRepositoryProvider).fetch();
    if (!ref.mounted) return;
    state = state.copyWith(profile: _mergeRemote(remote), initialized: true);
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

  Future<bool> saveDetailsPersisted({
    required String fullName,
    required String phoneNumber,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String medicalNote,
  }) async {
    if (!_validDetails(
      fullName: fullName,
      phoneNumber: phoneNumber,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      medicalNote: medicalNote,
    )) {
      return false;
    }
    if (!ref.read(runtimeApiIntegrationProvider)) {
      return saveDetails(
        fullName: fullName,
        phoneNumber: phoneNumber,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        medicalNote: medicalNote,
      );
    }
    final remote = await ref
        .read(profileRepositoryProvider)
        .update(
          fullName: fullName,
          phoneNumber: ProfileValidation.normalizePhone(phoneNumber),
          emergencyContactName: emergencyContactName,
          emergencyContactPhone: ProfileValidation.normalizePhone(
            emergencyContactPhone,
          ),
          medicalNote: medicalNote,
          homeAddress: state.profile.defaultAddress,
          workAddress: state.profile.workAddress,
        );
    if (!ref.mounted) return false;
    state = state.copyWith(profile: _mergeRemote(remote), initialized: true);
    return true;
  }

  bool _validDetails({
    required String fullName,
    required String phoneNumber,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String medicalNote,
  }) =>
      ProfileValidation.fullName(fullName) == null &&
      ProfileValidation.phone(phoneNumber) == null &&
      ProfileValidation.phone(emergencyContactPhone, optional: true) == null &&
      emergencyContactName.trim().length <= 80 &&
      medicalNote.trim().length <= 240;

  UserProfile _mergeRemote(UserProfile remote) => UserProfile(
    id: remote.id,
    fullName: remote.fullName,
    phoneNumber: remote.phoneNumber,
    email: remote.email,
    avatarUrl: state.profile.avatarUrl,
    isVerified: state.profile.isVerified,
    memberTier: state.profile.memberTier,
    rewardPoints: state.profile.rewardPoints,
    emergencyContactName: remote.emergencyContactName,
    emergencyContactPhone: remote.emergencyContactPhone,
    defaultVehicle: state.profile.defaultVehicle,
    defaultAddress: remote.defaultAddress,
    workAddress: remote.workAddress,
    medicalNote: remote.medicalNote,
  );

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

final homeUserProvider = Provider.autoDispose.family<HomeUser, HomeUser?>((
  ref,
  seed,
) {
  final state = ref.watch(profileProvider);
  if (!state.initialized && seed != null) return seed;
  return HomeUser(
    displayName: state.profile.fullName,
    memberId: state.profile.id,
    membershipLabel: state.profile.memberTier,
    rewardPoints: state.profile.rewardPoints,
  );
});
