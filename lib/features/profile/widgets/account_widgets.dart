import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';
import '../../home/widgets/brand_backdrop.dart';
import '../providers/profile_provider.dart';

class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, required this.state, required this.onEdit});
  final ProfileState state;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    final fallback = const Icon(
      Icons.person_rounded,
      size: 66,
      color: HomeColors.text,
    );
    final avatar = state.avatarBytes != null
        ? Image.memory(
            state.avatarBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : profile.avatarUrl?.trim().isNotEmpty == true
        ? Image.network(
            profile.avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : fallback;
    return BrandBackdrop(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  tooltip: 'Chỉnh sửa tài khoản',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: HomeColors.text,
                  ),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: HomeColors.primary, width: 2),
                ),
                child: ClipOval(child: avatar),
              ),
              const SizedBox(height: 16),
              Text(
                profile.fullName.trim().isEmpty
                    ? 'Tài khoản của bạn'
                    : profile.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 22,
                    color: HomeColors.primary,
                  ),
                  const Text(
                    '5.0',
                    style: TextStyle(fontSize: 16, color: HomeColors.secondary),
                  ),
                  const Text(
                    '•',
                    style: TextStyle(color: HomeColors.secondary),
                  ),
                  Text(
                    profile.phoneNumber.isEmpty
                        ? 'Chưa cập nhật SĐT'
                        : profile.phoneNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      color: HomeColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountMenuGroup extends StatelessWidget {
  const AccountMenuGroup({super.key, required this.title, required this.items});
  final String title;
  final List<AccountMenuItem> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Text(
          title,
          style: const TextStyle(
            color: HomeColors.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Material(
        color: HomeColors.surface,
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              ListTile(
                key: ValueKey('account-${items[index].id}'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                leading: Icon(
                  items[index].icon,
                  color: HomeColors.secondary,
                  size: 26,
                ),
                title: Text(
                  items[index].label,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: HomeColors.secondary,
                  size: 20,
                ),
                onTap: items[index].onTap,
              ),
              if (index < items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1),
                ),
            ],
          ],
        ),
      ),
    ],
  );
}

class AccountMenuItem {
  const AccountMenuItem(this.id, this.label, this.icon, this.onTap);
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}
