import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'mechanic_forgot_password_screen.dart';
import 'mechanic_login_screen.dart';
import 'terms_and_commitment_screen.dart';

class MechanicAccountScreen extends StatelessWidget {
  const MechanicAccountScreen({super.key});

  Future<void> _editProfile(BuildContext context) async {
    final p = appState.profile;
    final nameController = TextEditingController(text: p.name);
    final bioController = TextEditingController(text: p.bio);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sửa hồ sơ', style: appText(20, weight: FontWeight.w800)),
            const SizedBox(height: 16),
            const FieldLabel('Họ tên hoặc tên thợ'),
            TextField(controller: nameController, style: appText(15)),
            const SizedBox(height: 14),
            const FieldLabel('Giới thiệu bản thân'),
            TextField(controller: bioController, minLines: 3, maxLines: 5, style: appText(15)),
            const SizedBox(height: 18),
            PrimaryButton(label: 'Lưu thay đổi', onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
    if (saved == true) {
      appState.updateProfile(name: nameController.text, bio: bioController.text);
    }
    nameController.dispose();
    bioController.dispose();
  }

  Future<void> _registerSkill(BuildContext context) async {
    final registered = appState.profile.skills.map((s) => s.name).toSet();
    final options = MockData.extraSkills.where((s) => !registered.contains(s.$1)).toList();
    if (options.isEmpty) {
      showAppSnack(context, 'Bạn đã đăng ký tất cả kỹ năng hiện có');
      return;
    }
    final picked = await showModalBottomSheet<(String, IconData)>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text('Đăng ký kỹ năng mới', style: appText(20, weight: FontWeight.w800)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Kỹ năng sẽ ở trạng thái Chờ xác minh cho đến khi Admin duyệt.',
                  style: appText(13.5, color: AppColors.textSub)),
            ),
            for (final s in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: IconCircle(icon: s.$2, size: 40),
                title: Text(s.$1, style: appText(15.5, weight: FontWeight.w700)),
                trailing: const Icon(Icons.add),
                onTap: () => Navigator.of(ctx).pop(s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    appState
        .registerSkill(Skill(name: picked.$1, icon: picked.$2, status: VerificationStatus.pending));
    if (context.mounted) showAppSnack(context, 'Đã gửi đăng ký kỹ năng "${picked.$1}"');
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đăng xuất?', style: appText(19, weight: FontWeight.w800)),
        content: Text('Bạn sẽ không nhận được offer mới cho đến khi đăng nhập lại.',
            style: appText(15, color: AppColors.textSub, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                Text('Hủy', style: appText(15, weight: FontWeight.w700, color: AppColors.textSub)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child:
                Text('Đăng xuất', style: appText(15, weight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    appState.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MechanicLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final p = appState.profile;
        void push(Widget screen) =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

        final settings = <(IconData, String, VoidCallback)>[
          (
            Icons.lock_outline,
            'Đổi mật khẩu',
            () => push(MechanicForgotPasswordScreen(email: p.email, title: 'Đổi mật khẩu')),
          ),
          (
            Icons.description_outlined,
            'Điều khoản sử dụng',
            () => push(const TermsAndCommitmentScreen(readOnly: true)),
          ),
          (
            Icons.shield_outlined,
            'Chính sách bảo mật',
            () => showAppSnack(context, 'Chính sách bảo mật sẽ mở trên trình duyệt'),
          ),
          (
            Icons.article_outlined,
            'Quy định dành cho thợ',
            () => push(const TermsAndCommitmentScreen(readOnly: true)),
          ),
          (
            Icons.help_outline,
            'Hướng dẫn nhận & xử lý đơn',
            () => showAppSnack(context, 'Hướng dẫn sẽ mở trên trình duyệt'),
          ),
          (
            Icons.call_outlined,
            'Liên hệ hỗ trợ',
            () => showAppSnack(context, 'Tổng đài hỗ trợ Thợ: ${MockData.supportHotline}'),
          ),
        ];

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text('Tài khoản', style: appText(30, weight: FontWeight.w900)),
              const SizedBox(height: 16),
              _BorderBox(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AvatarCircle(initial: p.initial, size: 64),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: appText(18, weight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              StatusBadge.neutral('Hạng ${p.tierName}'),
                              const StatusBadge.success('Đã duyệt', icon: Icons.check),
                            ],
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _editProfile(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.border, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text('Sửa', style: appText(14, weight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(p.bio, style: appText(14.5, color: AppColors.textSub, height: 1.5)),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  children: [
                    _QuickStat(value: '${p.experienceYears} năm', label: 'Kinh nghiệm'),
                    const VerticalDivider(width: 1),
                    _QuickStat(value: '${p.radiusKm} km', label: 'Bán kính nhận đơn'),
                    const VerticalDivider(width: 1),
                    _QuickStat(
                      value: '${p.rating}',
                      label: '${p.ratingCount} lượt đánh giá',
                      star: true,
                    ),
                  ],
                ),
              ),
              const Divider(height: 36),
              const SectionTitle(
                'Kỹ năng đã đăng ký',
                subtitle: 'Admin xác minh hoặc từ chối từng kỹ năng. Bạn chỉ có thể đăng ký, '
                    'không thể tự bật trạng thái xác minh.',
              ),
              const SizedBox(height: 12),
              _BorderBox(
                child: Column(
                  children: [
                    for (var i = 0; i < p.skills.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      _StatusRow(
                        icon: p.skills[i].icon,
                        title: p.skills[i].name,
                        status: p.skills[i].status,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlineActionButton(
                label: 'Đăng ký kỹ năng mới',
                icon: Icons.add,
                height: 52,
                onPressed: () => _registerSkill(context),
              ),
              const SizedBox(height: 28),
              const SectionTitle('Giấy tờ xác minh'),
              const SizedBox(height: 12),
              _BorderBox(
                child: Column(
                  children: [
                    for (var i = 0; i < p.documents.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      _StatusRow(
                        icon: p.documents[i].icon,
                        title: p.documents[i].name,
                        status: p.documents[i].status,
                        withIcon: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionTitle('Khu vực hoạt động', subtitle: 'Quận/huyện mặc định nhận đơn.'),
              const SizedBox(height: 12),
              _BorderBox(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: p.area,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.ink),
                    items: [
                      for (final d in MockData.districts)
                        DropdownMenuItem(
                          value: d,
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 22),
                              const SizedBox(width: 10),
                              Text(d, style: appText(16, weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) appState.setArea(v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const SectionTitle('Cài đặt & hỗ trợ'),
              const SizedBox(height: 12),
              _BorderBox(
                child: Column(
                  children: [
                    for (var i = 0; i < settings.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: IconCircle(icon: settings[i].$1, size: 40),
                        title: Text(settings[i].$2, style: appText(15.5, weight: FontWeight.w700)),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        onTap: settings[i].$3,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              MutedTextButton(
                label: 'Đăng xuất',
                color: AppColors.danger,
                onPressed: () => _logout(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BorderBox extends StatelessWidget {
  const _BorderBox({required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.value, required this.label, this.star = false});
  final String value;
  final String label;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (star) const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
              Text(value, style: appText(18, weight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: appText(12, color: AppColors.textSub)),
        ],
      ),
    );
  }
}

/// Dòng kỹ năng / giấy tờ: chỉ hiển thị badge trạng thái (không có switch).
class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.status,
    this.withIcon = false,
  });

  final IconData icon;
  final String title;
  final VerificationStatus status;
  final bool withIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconCircle(icon: icon, size: 44),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: appText(16, weight: FontWeight.w700))),
          StatusBadge.verification(status, withIcon: withIcon),
        ],
      ),
    );
  }
}
