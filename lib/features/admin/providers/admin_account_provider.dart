import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_validation.dart';
import '../../profile/models/profile_validation.dart';
import '../../profile/services/profile_account_service.dart';
import '../../profile/services/profile_device_service.dart';
import '../data/admin_account_data.dart';
import '../models/admin_account_models.dart';
import '../models/admin_models.dart';
import '../services/admin_account_service.dart';
import 'admin_providers.dart';

final adminAccountServiceProvider = Provider<AdminAccountService>(
  (ref) => const SessionAdminAccountService(),
);
final adminAccountProvider =
    NotifierProvider<AdminAccountController, AdminAccountState>(
      AdminAccountController.new,
    );

class AdminAccountController extends Notifier<AdminAccountState> {
  @override
  AdminAccountState build() => AdminAccountData.initial(
    ref.watch(adminSessionProvider),
    ref.read(adminClockProvider)(),
  );

  Future<AdminAccountResult> _run({
    required Future<void> Function() operation,
    required void Function() commit,
    required String action,
    String target = 'Tài khoản quản trị',
    bool superAdmin = false,
  }) async {
    final actor = ref.read(adminSessionProvider);
    if (actor?.isAdmin != true) {
      return const AdminAccountResult(
        false,
        'Bạn không có quyền truy cập khu vực này',
      );
    }
    if (superAdmin && !actor!.isSuperAdmin) {
      return const AdminAccountResult(
        false,
        'Chỉ SUPER ADMIN được thay đổi cấu hình và phân quyền.',
      );
    }
    if (state.busy) {
      return const AdminAccountResult(
        false,
        'Một thao tác khác đang được xử lý.',
      );
    }
    state = state.copyWith(busy: true);
    bool current() =>
        ref.mounted && identical(ref.read(adminSessionProvider), actor);
    try {
      await operation();
      if (!current()) {
        return const AdminAccountResult(false, 'Phiên đăng nhập đã thay đổi.');
      }
      commit();
      ref.read(adminAuditTrailProvider.notifier).record(action, target);
      return const AdminAccountResult(true);
    } catch (error) {
      return AdminAccountResult(false, switch (error) {
        AdminException() => error.message,
        ProfileAccountException() => error.message,
        ProfileDeviceException() => error.message,
        _AvatarCancelled() => null,
        _ => 'Không thể lưu thay đổi. Vui lòng thử lại.',
      });
    } finally {
      if (current()) state = state.copyWith(busy: false);
    }
  }

  Future<AdminAccountResult> updateProfile(AdminAccountProfile profile) {
    final error =
        ProfileValidation.fullName(profile.name) ??
        AuthValidation.email(profile.email) ??
        ProfileValidation.phone(profile.phone, optional: true);
    if (error != null) return Future.value(AdminAccountResult(false, error));
    final normalized = AdminAccountProfile(
      name: profile.name.trim(),
      email: profile.email.trim(),
      phone: ProfileValidation.normalizePhone(profile.phone),
    );
    return _run(
      operation: () =>
          ref.read(adminAccountServiceProvider).saveProfile(normalized),
      commit: () => state = state.copyWith(profile: normalized),
      action: 'Cập nhật hồ sơ quản trị',
    );
  }

  Future<AdminAccountResult> pickAvatar() {
    Uint8List? bytes;
    return _run(
      operation: () async {
        bytes = await ref.read(profileDeviceServiceProvider).pickAvatar();
        if (bytes == null) throw const _AvatarCancelled();
      },
      commit: () {
        if (bytes != null) {
          state = state.copyWith(avatarBytes: Uint8List.fromList(bytes!));
        }
      },
      action: 'Chọn ảnh đại diện',
    );
  }

  Future<AdminAccountResult> updateSettings(AdminOperatingSettings settings) {
    if (!settings.feePercent.isFinite ||
        settings.feePercent < 0 ||
        settings.feePercent > 100 ||
        !settings.weatherFactor.isFinite ||
        settings.weatherFactor < 1 ||
        settings.weatherFactor > 3 ||
        !settings.sosFactor.isFinite ||
        settings.sosFactor < 1 ||
        settings.sosFactor > 5) {
      return Future.value(
        const AdminAccountResult(
          false,
          'Phí từ 0–100%, hệ số thời tiết từ 1–3 và SOS từ 1–5.',
        ),
      );
    }
    final previous = state.settings;
    return _run(
      superAdmin:
          previous.feePercent != settings.feePercent ||
          previous.weatherFactor != settings.weatherFactor ||
          previous.sosFactor != settings.sosFactor ||
          previous.sandbox != settings.sandbox,
      operation: () =>
          ref.read(adminAccountServiceProvider).saveSettings(settings),
      commit: () => state = state.copyWith(settings: settings),
      action: 'Cập nhật cấu hình vận hành',
    );
  }

  Future<AdminAccountResult> changePassword(
    String currentPassword,
    String password,
  ) {
    final error =
        ProfileValidation.currentPassword(currentPassword) ??
        ProfileValidation.newPassword(password, currentPassword);
    if (error != null) return Future.value(AdminAccountResult(false, error));
    return _run(
      operation: () => ref
          .read(profileAccountServiceProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: password,
          ),
      commit: () {},
      action: 'Đổi mật khẩu',
    );
  }

  Future<AdminAccountResult> updateStaff(AdminStaffMember member) {
    if (!state.staff.any((item) => item.id == member.id) ||
        member.id == ref.read(adminSessionProvider)?.id) {
      return Future.value(
        const AdminAccountResult(false, 'Không thể thay đổi tài khoản này.'),
      );
    }
    final existing = state.staff.firstWhere((item) => item.id == member.id);
    final updated = existing.copyWith(role: member.role, onDuty: member.onDuty);
    return _run(
      superAdmin: true,
      operation: () => ref.read(adminAccountServiceProvider).saveStaff(updated),
      commit: () => state = state.copyWith(
        staff: List.unmodifiable([
          for (final item in state.staff)
            if (item.id == member.id) updated else item,
        ]),
      ),
      action: 'Cập nhật phân quyền / ca trực',
      target: member.id,
    );
  }

  Future<AdminAccountResult> requestSupport(String subject, String message) {
    if (subject.trim().isEmpty ||
        subject.trim().length > 100 ||
        message.trim().length < 10 ||
        message.trim().length > 2000) {
      return Future.value(
        const AdminAccountResult(
          false,
          'Nhập tiêu đề tối đa 100 ký tự và nội dung từ 10–2000 ký tự.',
        ),
      );
    }
    final request = AdminSupportRequest(
      id: 'HT-${(state.requests.length + 1).toString().padLeft(4, '0')}',
      subject: subject.trim(),
      message: message.trim(),
      at: ref.read(adminClockProvider)(),
    );
    return _run(
      operation: () =>
          ref.read(adminAccountServiceProvider).saveSupportRequest(request),
      commit: () => state = state.copyWith(
        requests: List.unmodifiable([request, ...state.requests]),
      ),
      action: 'Lưu yêu cầu hỗ trợ kỹ thuật',
      target: request.id,
    );
  }
}

class _AvatarCancelled implements Exception {
  const _AvatarCancelled();
}
