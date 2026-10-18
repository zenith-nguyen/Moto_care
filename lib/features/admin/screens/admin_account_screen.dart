import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import '../data/admin_account_data.dart';
import '../models/admin_models.dart';
import '../providers/admin_account_provider.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_account_cards.dart';
import '../widgets/admin_account_edit_dialog.dart';
import '../widgets/admin_account_sheets.dart';
import '../widgets/admin_common.dart';

class AdminAccountScreen extends ConsumerWidget {
  const AdminAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(adminSessionProvider);
    if (session?.isAdmin != true) return const AdminStateView.forbidden();
    final state = ref.watch(adminAccountProvider);
    void edit(AdminAccountEditor editor) =>
        showAdminAccountEditor(context, editor);
    void sheet(AdminAccountSheet sheet) =>
        showAdminAccountSheet(context, sheet);
    return SingleChildScrollView(
      key: const PageStorageKey('admin-account-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminPageTitle(title: 'Tài khoản Quản trị'),
              const SizedBox(height: 24),
              AdminAccountProfileCard(
                session: session!,
                state: state,
                onEdit: () => edit(AdminAccountEditor.profile),
                onPassword: () => edit(AdminAccountEditor.password),
                onAvatar: () async {
                  final result = await ref
                      .read(adminAccountProvider.notifier)
                      .pickAvatar();
                  if (context.mounted &&
                      !result.success &&
                      result.message != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(result.message!)));
                  }
                },
              ),
              const SizedBox(height: 28),
              const AdminAccountSectionTitle('Quản lý & Cấu hình Vận hành'),
              AdminAccountListTile(
                title: 'Cấu hình Phí & Hệ số',
                subtitle:
                    'Thời tiết ×${state.settings.weatherFactor} · SOS ×${state.settings.sosFactor}',
                icon: Icons.tune_rounded,
                onTap: state.busy ? null : () => edit(AdminAccountEditor.fees),
              ),
              AdminAccountListTile(
                title: 'Cài đặt Cảnh báo SOS',
                subtitle: state.settings.sosSound
                    ? 'Âm thanh chuông đang bật'
                    : 'Âm thanh chuông đã tắt',
                icon: Icons.notifications_active_outlined,
                onTap: state.busy
                    ? null
                    : () => edit(AdminAccountEditor.alerts),
              ),
              AdminAccountListTile(
                title: 'Chế độ Sandbox',
                subtitle: state.settings.sandbox
                    ? 'Test Mode đang bật'
                    : 'Test Mode đã tắt',
                icon: Icons.science_outlined,
                onTap: null,
                trailing: Semantics(
                  label: 'Chế độ Sandbox',
                  child: Switch.adaptive(
                    value: state.settings.sandbox,
                    onChanged: state.busy
                        ? null
                        : (value) => _changeSandbox(context, ref, value),
                  ),
                ),
              ),
              AdminAccountListTile(
                title: 'Phân quyền Quản trị',
                subtitle: 'Admin & Nhân viên ca trực',
                icon: Icons.admin_panel_settings_outlined,
                onTap: () => sheet(AdminAccountSheet.staff),
              ),
              const SizedBox(height: 16),
              const AdminAccountSectionTitle('Nhật ký & Bảo mật'),
              AdminAccountListTile(
                title: 'Nhật ký thao tác (Audit Trail)',
                subtitle: 'Lịch sử duyệt tiền, duyệt thợ',
                icon: Icons.history_rounded,
                onTap: () => sheet(AdminAccountSheet.audit),
              ),
              AdminAccountListTile(
                title: 'Lịch sử đăng nhập & Thiết bị',
                subtitle: 'Kiểm tra các phiên truy cập',
                icon: Icons.devices_outlined,
                onTap: () => sheet(AdminAccountSheet.logins),
              ),
              const SizedBox(height: 16),
              const AdminAccountSectionTitle('Thông tin & Hỗ trợ'),
              AdminAccountListTile(
                title: 'Tài liệu Hướng dẫn Vận hành Admin',
                subtitle: 'Quy trình điều phối và đối soát',
                icon: Icons.menu_book_outlined,
                onTap: () => sheet(AdminAccountSheet.guide),
              ),
              AdminAccountListTile(
                title: 'Liên hệ Kỹ thuật (Dev Team Support)',
                subtitle: 'Tạo và theo dõi yêu cầu hỗ trợ',
                icon: Icons.support_agent_rounded,
                onTap: state.busy
                    ? null
                    : () => edit(AdminAccountEditor.support),
              ),
              const SizedBox(height: 12),
              const Text(
                AdminAccountData.version,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AdminTokens.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEBEE),
                  foregroundColor: AdminTokens.primaryRed,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: state.busy
                    ? null
                    : () async {
                        final success = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const _SignOutDialog(),
                        );
                        if (context.mounted && success == true) {
                          context.go('/login');
                        }
                      },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeSandbox(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          enabled ? 'Bật Chế độ Sandbox?' : 'Tắt Chế độ Sandbox?',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Xác nhận thay đổi Test Mode trong cấu hình vận hành.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final result = await ref
        .read(adminAccountProvider.notifier)
        .updateSettings(
          ref.read(adminAccountProvider).settings.copyWith(sandbox: enabled),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Đã cập nhật Chế độ Sandbox.'
              : result.message ?? 'Không thể lưu thay đổi.',
        ),
      ),
    );
  }
}

class _SignOutDialog extends ConsumerStatefulWidget {
  const _SignOutDialog();
  @override
  ConsumerState<_SignOutDialog> createState() => _SignOutDialogState();
}

class _SignOutDialogState extends ConsumerState<_SignOutDialog> {
  bool _submitted = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSignOutProvider);
    final busy = state.isLoading;
    final forbidden =
        ref.watch(adminSessionProvider)?.isAdmin != true ||
        (_submitted &&
            state.error is AdminException &&
            (state.error as AdminException).forbidden);
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        scrollable: true,
        title: const Text('Xác nhận đăng xuất', textAlign: TextAlign.center),
        content: forbidden
            ? const AdminStateView.forbidden()
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Bạn muốn kết thúc phiên quản trị hiện tại?'),
                  if (busy) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const Text('Đang đăng xuất…'),
                  ],
                  if (_submitted && state.hasError) ...[
                    const SizedBox(height: 16),
                    const Text('Không thể đăng xuất. Vui lòng thử lại.'),
                  ],
                ],
              ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          if (!forbidden)
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => _submitted = true);
                      final success = await ref
                          .read(adminSignOutProvider.notifier)
                          .signOut();
                      if (context.mounted && success) {
                        Navigator.of(context).pop(true);
                      }
                    },
              child: Text(
                _submitted && state.hasError ? 'Thử lại / Retry' : 'Xác nhận',
              ),
            ),
        ],
      ),
    );
  }
}
