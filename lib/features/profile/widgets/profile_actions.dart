import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_actions_provider.dart';
import '../providers/profile_provider.dart';
import '../services/profile_account_service.dart';
import '../theme/profile_dashboard_theme.dart';
import 'change_password_dialog.dart';

/// Presentation adapter for profile dialogs, navigation and operation feedback.
class ProfileActions {
  const ProfileActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  ProfileActionsController get _controller =>
      ref.read(profileActionsProvider.notifier);

  void notice(ProfileActionResult result) {
    if (!context.mounted || result.message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message!)));
  }

  Future<void> recoverAvatar() async =>
      notice(await _controller.recoverAvatar());
  Future<void> pickAvatar() async => notice(await _controller.pickAvatar());
  Future<void> toggleBiometric(bool enabled) async =>
      notice(await _controller.toggleBiometric(enabled));

  Future<void> changePassword() async {
    final result = await _controller.authenticate();
    notice(result);
    if (!context.mounted || !result.success) return;
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangePasswordDialog(
        service: ref.read(profileAccountServiceProvider),
      ),
    );
    if (changed == true) {
      notice(const ProfileActionResult(true, 'Đã đổi mật khẩu.'));
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ProfileDashboardTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> logout() async {
    if (!await _confirm(
          title: 'Đăng xuất khỏi MotoCare?',
          message: 'Thông tin chỉnh sửa trong phiên dùng thử sẽ được xóa khỏi bộ nhớ.',
          action: 'Đăng xuất',
        ) ||
        !context.mounted) {
      return;
    }
    ref.read(profileProvider.notifier).clearSession();
    context.go('/login');
  }

  Future<void> deleteAccount() async {
    final authenticated = await _controller.authenticate();
    notice(authenticated);
    if (!context.mounted || !authenticated.success) return;
    if (!await _confirm(
          title: 'Xóa tài khoản?',
          message: 'Tài khoản và dữ liệu liên quan sẽ bị xóa khi dịch vụ xác nhận. Bạn không thể khôi phục tài khoản sau khi xóa.',
          action: 'Xóa tài khoản',
        ) ||
        !context.mounted) {
      return;
    }
    final result = await _controller.deleteAccount();
    notice(result);
    if (context.mounted && result.success) context.go('/login');
  }
}
