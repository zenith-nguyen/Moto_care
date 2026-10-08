import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Màn 5 — Hồ sơ & cài đặt dịch vụ thợ.
class MechanicProfileScreen extends StatelessWidget {
  const MechanicProfileScreen({super.key});

  Future<void> _edit(BuildContext context, AppState state) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initial: state.profile.displayName),
    );
    if (name == null || !context.mounted) return;
    state.updateDisplayName(name);
    showAppSnack(context, 'Đã cập nhật tên tiệm / thợ.');
  }

  Future<void> _logout(BuildContext context, AppState state) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('Đăng xuất?', style: appText(17, weight: FontWeight.w800)),
        content: Text(
          'Bạn sẽ ngừng nhận đơn cho đến khi đăng nhập lại.',
          style: appText(14, color: AppColors.textSub, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Ở lại', style: appText(14, weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Đăng xuất',
              style: appText(
                14,
                weight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    state.setOnline(false);
    state.setTab(0);
    showAppSnack(
      context,
      'Đã đăng xuất (demo) — trạng thái chuyển sang Tạm nghỉ.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Text('Hồ sơ', style: appText(22, weight: FontWeight.w800)),
              const SizedBox(height: 14),
              _ProfileHeader(
                profile: profile,
                onEdit: () => _edit(context, state),
              ),
              const SizedBox(height: 24),

              // ---- Dịch vụ nhận đơn ----
              const SectionTitle('Dịch vụ nhận đơn'),
              const SizedBox(height: 4),
              Text(
                'Chỉ nhận đơn thuộc các dịch vụ đang bật.',
                style: appText(12.5, color: AppColors.textSub),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < state.services.length; i++) ...[
                      _ServiceRow(
                        skill: state.services[i],
                        onChanged: (v) =>
                            state.setService(state.services[i], v),
                      ),
                      if (i != state.services.length - 1)
                        const Divider(height: 1, color: AppColors.border),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---- Thông tin cá nhân & giấy phép ----
              const SectionTitle('Thông tin cá nhân & giấy phép'),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    _DocumentTile(
                      icon: Icons.badge_outlined,
                      title: 'CCCD / Giấy ĐKKD',
                      onTap: () => showAppSnack(
                        context,
                        'Xem chi tiết CCCD / Giấy ĐKKD (demo).',
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    _DocumentTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Chứng chỉ thợ',
                      onTap: () => showAppSnack(
                        context,
                        'Xem chi tiết chứng chỉ thợ (demo).',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---- Khu vực hoạt động ----
              const SectionTitle('Khu vực hoạt động'),
              const SizedBox(height: 4),
              Text(
                'Quận/huyện mặc định nhận đơn.',
                style: appText(12.5, color: AppColors.textSub),
              ),
              const SizedBox(height: 10),
              _AreaDropdown(value: profile.area, onChanged: state.setArea),
              const SizedBox(height: 28),

              // ---- Chuyển về giao diện Khách ----
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => state.switchMode(AppMode.customer),
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  label: Text(
                    'Chuyển sang giao diện Khách',
                    style: appText(14.5, weight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ---- Đăng xuất ----
              Center(
                child: TextButton(
                  onPressed: () => _logout(context, state),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: const Size(160, 48),
                  ),
                  child: Text(
                    'Đăng xuất',
                    style: appText(
                      15,
                      weight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});
  final MechanicProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AvatarCircle(initial: profile.initial, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: appText(17, weight: FontWeight.w800, height: 1.2),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thợ: ${profile.ownerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(12.5, color: AppColors.textSub),
                ),
                const SizedBox(height: 8),
                if (profile.verified) const VerifiedBadge(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(
              'Chỉnh sửa',
              style: appText(12.5, weight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.skill, required this.onChanged});
  final ServiceSkill skill;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = skill.enabled;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: on ? AppColors.ink : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              skill.icon,
              size: 21,
              color: on ? Colors.white : AppColors.disabled,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill.name, style: appText(14.5, weight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(
                  skill.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appText(12, color: AppColors.textSub),
                ),
              ],
            ),
          ),
          Switch(
            value: on,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.online,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.disabled,
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 21, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: appText(14.5, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            const VerifiedBadge(label: 'Đã xác minh'),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}

class _AreaDropdown extends StatelessWidget {
  const _AreaDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.ink,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                style: appText(15, weight: FontWeight.w600),
                items: [
                  for (final d in MockData.districts)
                    DropdownMenuItem<String>(
                      value: d,
                      child: Text(
                        d,
                        style: appText(15, weight: FontWeight.w600),
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initial});
  final String initial;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        'Chỉnh sửa hồ sơ',
        style: appText(17, weight: FontWeight.w800),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: appText(15),
        decoration: const InputDecoration(labelText: 'Tên tiệm / thợ'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Hủy',
            style: appText(
              14,
              weight: FontWeight.w700,
              color: AppColors.textSub,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text),
          child: Text(
            'Lưu',
            style: appText(
              14,
              weight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}
