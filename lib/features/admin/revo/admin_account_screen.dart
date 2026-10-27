import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/theme/admin_tokens.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../auth/domain/app_user.dart';
import 'revo_admin_style.dart';

/// Admin account tab in the REVO prototype look. Profile + sign out are wired
/// to the real session; "Cấu hình Phí & Hệ số" shows the REAL pricing policy
/// (read-only). Features that need new backend (audit log, permissions, login
/// history) are present but marked as in-progress on tap rather than faked.
class RevoAdminAccountScreen extends ConsumerStatefulWidget {
  const RevoAdminAccountScreen({super.key});

  @override
  ConsumerState<RevoAdminAccountScreen> createState() =>
      _RevoAdminAccountScreenState();
}

class _RevoAdminAccountScreenState
    extends ConsumerState<RevoAdminAccountScreen> {
  bool _sosSound = true;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionSignedIn ? session.session.user : null;
    final liveBackend = ref.watch(runtimeApiIntegrationProvider);

    return ColoredBox(
      color: AdminTokens.background,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.paddingOf(context).top + 16,
          16,
          120,
        ),
        children: [
          Text(
            'Tài khoản Quản trị',
            textAlign: TextAlign.center,
            style: revoFont(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AdminTokens.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 20),
          _ProfileCard(user: user),
          const SizedBox(height: 24),
          _SectionLabel('Quản lý & Cấu hình Vận hành'),
          const SizedBox(height: 10),
          _Card(
            children: [
              _Tile(
                icon: Icons.tune_rounded,
                title: 'Cấu hình Phí & Hệ số',
                subtitle: 'Thời tiết: Vừa ×1.1 · Nặng ×1.2',
                onTap: () => _showPricingPolicy(context),
              ),
              _divider(),
              _Tile(
                icon: Icons.notifications_active_outlined,
                title: 'Cảnh báo SOS',
                subtitle: _sosSound
                    ? 'Âm thanh chuông đang bật'
                    : 'Âm thanh chuông đang tắt',
                trailing: Switch(
                  value: _sosSound,
                  activeThumbColor: AdminTokens.primaryBlue,
                  onChanged: (v) => setState(() => _sosSound = v),
                ),
              ),
              _divider(),
              _Tile(
                icon: Icons.cloud_done_outlined,
                title: 'Chế độ kết nối',
                subtitle: liveBackend
                    ? 'Đang kết nối máy chủ thật'
                    : 'Chế độ demo (offline)',
                trailing: _StatusDot(on: liveBackend),
              ),
              _divider(),
              _Tile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Phân quyền Quản trị',
                subtitle: 'Admin & nhân viên ca trực',
                onTap: () => _comingSoon(context, 'Phân quyền quản trị'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('Nhật ký & Bảo mật'),
          const SizedBox(height: 10),
          _Card(
            children: [
              _Tile(
                icon: Icons.history_rounded,
                title: 'Nhật ký thao tác (Audit Trail)',
                subtitle: 'Lịch sử duyệt tiền, duyệt thợ',
                onTap: () => _comingSoon(context, 'Nhật ký thao tác'),
              ),
              _divider(),
              _Tile(
                icon: Icons.devices_outlined,
                title: 'Lịch sử đăng nhập & Thiết bị',
                subtitle: 'Kiểm tra các phiên truy cập',
                onTap: () => _comingSoon(context, 'Lịch sử đăng nhập'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('Thông tin & Hỗ trợ'),
          const SizedBox(height: 10),
          _Card(
            children: [
              _Tile(
                icon: Icons.menu_book_outlined,
                title: 'Tài liệu Hướng dẫn Vận hành',
                subtitle: 'Quy trình điều phối và đối soát',
                onTap: () => _comingSoon(context, 'Tài liệu hướng dẫn'),
              ),
              _divider(),
              _Tile(
                icon: Icons.support_agent_outlined,
                title: 'Liên hệ Kỹ thuật (Dev Team)',
                subtitle: 'Tạo và theo dõi yêu cầu hỗ trợ',
                onTap: () => _comingSoon(context, 'Liên hệ kỹ thuật'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Phiên bản REVO Admin v1.0 (Build 2026)',
              style: revoFont(fontSize: 11, color: AdminTokens.muted),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _confirmSignOut(context),
              style: FilledButton.styleFrom(
                backgroundColor: AdminTokens.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature đang được hoàn thiện.')));
  }

  void _showPricingPolicy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AdminTokens.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cấu hình Phí & Hệ số',
              style: revoFont(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AdminTokens.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chính sách đang áp dụng trên hệ thống (chỉ xem).',
              style: revoFont(fontSize: 12, color: AdminTokens.muted),
            ),
            const SizedBox(height: 16),
            _policyRow('Thời tiết bình thường', '×1.0 (không phụ phí)'),
            _policyRow('Thời tiết xấu vừa', '×1.1 (+10%)'),
            _policyRow('Thời tiết nguy hiểm', '×1.2 (+20%)'),
            const SizedBox(height: 12),
            Text(
              'Phụ phí thời tiết được tính theo dữ liệu Open-Meteo thời gian '
              'thực tại vị trí sự cố. Thay đổi hệ số cần cập nhật backend và '
              'kiểm thử vì ảnh hưởng trực tiếp tới số tiền khách trả.',
              style: revoFont(
                fontSize: 12,
                color: AdminTokens.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _policyRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: revoFont(fontSize: 14, color: AdminTokens.text),
          ),
        ),
        Text(
          value,
          style: revoFont(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AdminTokens.primaryBlue,
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc muốn đăng xuất khỏi tài khoản quản trị?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionControllerProvider.notifier).signOut();
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Quản trị viên';
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    final email = user?.email;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AdminTokens.accountBackgroundGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminTokens.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AdminTokens.primaryBlue,
            child: Text(
              initial,
              style: revoFont(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: revoFont(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AdminTokens.text,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AdminTokens.activePill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'QUẢN TRỊ VIÊN',
                    style: revoFont(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AdminTokens.primaryBlue,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: revoFont(fontSize: 12, color: AdminTokens.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: revoFont(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: AdminTokens.text,
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AdminTokens.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AdminTokens.border),
    ),
    child: Column(children: children),
  );
}

Widget _divider() =>
    const Divider(height: 1, color: AdminTokens.border, indent: 56);

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AdminTokens.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: revoFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AdminTokens.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: revoFont(fontSize: 12, color: AdminTokens.muted),
                ),
              ],
            ),
          ),
          trailing ??
              (onTap != null
                  ? const Icon(
                      Icons.chevron_right_rounded,
                      color: AdminTokens.muted,
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    ),
  );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: on ? AdminTokens.success : AdminTokens.muted,
      shape: BoxShape.circle,
    ),
  );
}
