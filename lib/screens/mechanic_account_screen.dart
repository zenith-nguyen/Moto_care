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
            Text('Sửa hồ sơ', style: appText(20, weight: FontWeight.w600)),
            const SizedBox(height: 16),
            const FieldLabel('Họ tên / Tên thợ'),
            TextField(controller: nameController, style: appText(15)),
            const SizedBox(height: 14),
            const FieldLabel('Giới thiệu bản thân'),
            TextField(
              controller: bioController,
              minLines: 3,
              maxLines: 5,
              style: appText(15),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
                ),
              ),
            ),
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
    final options = MockData.extraSkills.where((s) => !registered.contains(s)).toList();
    if (options.isEmpty) {
      showAppSnack(context, 'Bạn đã đăng ký tất cả kỹ năng hiện có');
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text('Đăng ký kỹ năng mới', style: appText(20, weight: FontWeight.w600)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Kỹ năng sẽ ở trạng thái Chờ xác minh cho đến khi Admin duyệt.',
                style: appText(13.5, color: AppColors.textSub),
              ),
            ),
            for (final s in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.shield_outlined),
                title: Text(s, style: appText(15.5, weight: FontWeight.w500)),
                trailing: const Icon(Icons.add),
                onTap: () => Navigator.of(ctx).pop(s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    appState.registerSkill(picked);
    if (context.mounted) showAppSnack(context, 'Đã gửi đăng ký kỹ năng "$picked"');
  }

  Future<void> _pickArea(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Khu vực hoạt động', style: appText(20, weight: FontWeight.w600)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final d in MockData.districts)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(d, style: appText(15.5, weight: FontWeight.w500)),
                      trailing: d == appState.profile.area
                          ? const Icon(Icons.check, color: AppColors.success)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(d),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) appState.setArea(picked);
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Đăng xuất?', style: appText(19, weight: FontWeight.w600)),
        content: Text(
          'Bạn sẽ không nhận được offer mới cho đến khi đăng nhập lại.',
          style: appText(15, color: AppColors.textSub, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                Text('Hủy', style: appText(15, weight: FontWeight.w600, color: AppColors.textSub)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: const StadiumBorder(),
            ),
            child:
                Text('Đăng xuất', style: appText(15, weight: FontWeight.w700, color: Colors.white)),
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
          child: Column(
            children: [
              ScreenHeader(
                title: 'Tài khoản',
                showBack: false,
                trailing: TextButton(
                  onPressed: () => _editProfile(context),
                  child: Text('Sửa', style: appText(16, weight: FontWeight.w600)),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    Row(
                      children: [
                        AvatarCircle(initials: p.initials, size: 76),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(p.name, style: appText(21, weight: FontWeight.w600)),
                                  StatusBadge.neutral('Hạng ${p.tierName}'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const StatusBadge.success('Đã duyệt', icon: Icons.check),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(p.bio, style: appText(15, color: AppColors.textSub, height: 1.5)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _QuickStat(value: '${p.experienceYears} năm', label: 'Kinh nghiệm'),
                        const SizedBox(width: 10),
                        _QuickStat(value: '${p.radiusKm} km', label: 'Bán kính nhận đơn'),
                        const SizedBox(width: 10),
                        _QuickStat(value: '${p.rating}★', label: 'Đánh giá'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ShadowCard(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kỹ năng đã đăng ký', style: appText(16.5, weight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          for (final s in p.skills) _StatusRow(title: s.name, status: s.status),
                          const SizedBox(height: 8),
                          Text(
                            'Admin xác minh hoặc từ chối từng kỹ năng — bạn chỉ có thể đăng ký, '
                            'không tự xác minh được.',
                            style: appText(13.5, color: AppColors.textSub, height: 1.45),
                          ),
                          const SizedBox(height: 16),
                          OutlineActionButton(
                            label: '+ Đăng ký kỹ năng mới',
                            height: 50,
                            onPressed: () => _registerSkill(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ShadowCard(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Giấy tờ xác minh', style: appText(16.5, weight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          for (final d in p.documents) _StatusRow(title: d.name, status: d.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _pickArea(context),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: SurfaceCard(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Khu vực hoạt động',
                                      style: appText(15.5, weight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(p.area, style: appText(16.5, weight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textSub),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Cài đặt & hỗ trợ', style: appText(16.5, weight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ShadowCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          for (var i = 0; i < settings.length; i++) ...[
                            if (i > 0) const Divider(height: 1, indent: 20, endIndent: 20),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                              leading: Icon(settings[i].$1, color: AppColors.ink),
                              title: Text(settings[i].$2,
                                  style: appText(15.5, weight: FontWeight.w500)),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                              onTap: settings[i].$3,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    MutedTextButton(
                      label: 'Đăng xuất',
                      color: AppColors.danger,
                      onPressed: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(value, style: appText(19, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: appText(12.5, color: AppColors.textSub, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dòng kỹ năng / giấy tờ: chỉ hiển thị badge trạng thái (không có switch).
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.title, required this.status});

  final String title;
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 24),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: appText(16, weight: FontWeight.w500))),
          const SizedBox(width: 8),
          StatusBadge.verification(status),
        ],
      ),
    );
  }
}
