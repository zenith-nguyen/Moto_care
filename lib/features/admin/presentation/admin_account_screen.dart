import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../auth/domain/app_user.dart';

/// Admin account tab. Shows the signed-in administrator and the sign-out action.
///
/// It deliberately does not expose fee configuration, payout permissions or the
/// audit log yet: those are money- and policy-sensitive and need real backend
/// endpoints, so they are not faked here.
class AdminAccountScreen extends ConsumerWidget {
  const AdminAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final user = session is SessionSignedIn ? session.session.user : null;
    return Scaffold(
      backgroundColor: AdminTokens.background,
      appBar: AppBar(
        backgroundColor: AdminTokens.surface,
        foregroundColor: AdminTokens.text,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Tài khoản',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 16),
          const _SectionLabel('Hệ thống'),
          const SizedBox(height: 10),
          _InfoCard(
            children: [
              _InfoTile(
                icon: Icons.verified_user_outlined,
                label: 'Vai trò',
                value: 'Quản trị viên (ADMIN)',
              ),
              _InfoTile(
                icon: Icons.shield_outlined,
                label: 'Phạm vi',
                value: 'Duyệt thợ, đơn hàng, tài chính và đối soát',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Sắp có'),
          const SizedBox(height: 10),
          _InfoCard(
            children: [
              _InfoTile(
                icon: Icons.tune_rounded,
                label: 'Cấu hình phí & phụ phí',
                value: 'Cần API backend, sẽ bổ sung sau',
                muted: true,
              ),
              _InfoTile(
                icon: Icons.notifications_active_outlined,
                label: 'Cảnh báo SOS',
                value: 'Cần API backend, sẽ bổ sung sau',
                muted: true,
              ),
              _InfoTile(
                icon: Icons.history_rounded,
                label: 'Nhật ký thao tác (audit log)',
                value: 'Cần API backend, sẽ bổ sung sau',
                muted: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminTokens.primaryRed,
              side: const BorderSide(color: AdminTokens.primaryRed),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
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
    final email = user?.email;
    final phone = user?.phone;
    final initial = name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
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
              style: const TextStyle(
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AdminTokens.text,
                  ),
                ),
                const SizedBox(height: 4),
                if (email != null && email.isNotEmpty)
                  Text(email, style: const TextStyle(color: AdminTokens.muted)),
                if (phone != null && phone.isNotEmpty)
                  Text(phone, style: const TextStyle(color: AdminTokens.muted)),
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
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: AdminTokens.text,
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AdminTokens.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AdminTokens.border),
    ),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AdminTokens.border),
          children[i],
        ],
      ],
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
          color: muted ? AdminTokens.muted : AdminTokens.primaryBlue,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AdminTokens.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: AdminTokens.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
