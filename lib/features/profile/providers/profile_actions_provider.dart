import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/profile_account_service.dart';
import '../services/profile_device_service.dart';
import 'profile_provider.dart';

final profileActionsProvider =
    NotifierProvider.autoDispose<ProfileActionsController, bool>(
      ProfileActionsController.new,
    );

class ProfileActionResult {
  const ProfileActionResult(this.success, [this.message]);
  final bool success;
  final String? message;
}

/// Coordinates device/account operations without retaining results from an
/// account that has been changed or signed out while an operation was pending.
class ProfileActionsController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<ProfileActionResult> _run(
    Future<ProfileActionResult> Function(String userId) operation,
  ) async {
    if (state) return const ProfileActionResult(false);
    final userId = ref.read(profileProvider).profile.id;
    state = true;
    try {
      return await operation(userId);
    } catch (error) {
      return ProfileActionResult(false, switch (error) {
        ProfileDeviceException() => error.message,
        ProfileAccountException() => error.message,
        _ => 'Không thể hoàn tất thao tác. Vui lòng thử lại.',
      });
    } finally {
      if (ref.mounted) state = false;
    }
  }

  bool _isCurrent(String userId) =>
      ref.mounted && ref.read(profileProvider).profile.id == userId;

  Future<bool> _authenticate(String userId, {bool force = false}) async {
    if (!force && !ref.read(profileProvider).biometricEnabled) return true;
    final success = await ref.read(profileDeviceServiceProvider).authenticate();
    return success && _isCurrent(userId);
  }

  static const _cancelled = ProfileActionResult(
    false,
    'Chưa xác thực. Thông tin của bạn được giữ nguyên.',
  );

  Future<ProfileActionResult> authenticate() => _run(
    (userId) async => await _authenticate(userId)
        ? const ProfileActionResult(true)
        : _cancelled,
  );

  Future<ProfileActionResult> recoverAvatar() => _run((userId) async {
    final device = ref.read(profileDeviceServiceProvider);
    final bytes = await (() async {
      try {
        return await device.recoverAvatar();
      } on ProfileDeviceException {
        rethrow;
      } catch (_) {
        return null;
      }
    })();
    if (!_isCurrent(userId)) return const ProfileActionResult(false);
    if (bytes != null && ref.read(profileProvider).avatarBytes == null) {
      ref.read(profileProvider.notifier).setAvatar(bytes);
    }
    return const ProfileActionResult(true);
  });

  Future<ProfileActionResult> pickAvatar() => _run((userId) async {
    if (!await _authenticate(userId)) return _cancelled;
    if (!_isCurrent(userId)) return const ProfileActionResult(false);
    final bytes = await ref.read(profileDeviceServiceProvider).pickAvatar();
    if (!_isCurrent(userId) || bytes == null) {
      return const ProfileActionResult(false);
    }
    ref.read(profileProvider.notifier).setAvatar(bytes);
    return const ProfileActionResult(
      true,
      'Đã cập nhật ảnh đại diện trong phiên dùng thử.',
    );
  });

  Future<ProfileActionResult> toggleBiometric(bool enabled) =>
      _run((userId) async {
        if (!await _authenticate(userId, force: true)) return _cancelled;
        ref.read(profileProvider.notifier).setBiometricEnabled(enabled);
        return ProfileActionResult(
          true,
          enabled
              ? 'Đã bật xác thực khi chỉnh sửa hồ sơ.'
              : 'Đã tắt xác thực khi chỉnh sửa hồ sơ.',
        );
      });

  Future<ProfileActionResult> deleteAccount() => _run((userId) async {
    await ref.read(profileAccountServiceProvider).deleteAccount(userId);
    if (!_isCurrent(userId)) return const ProfileActionResult(false);
    ref.read(profileProvider.notifier).clearSession();
    return const ProfileActionResult(true);
  });
}
