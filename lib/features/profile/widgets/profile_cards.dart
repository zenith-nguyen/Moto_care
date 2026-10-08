import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';
import '../models/user_profile.dart';
import '../theme/profile_theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onEditAvatar,
    this.avatarBytes,
  });

  final UserProfile profile;
  final Uint8List? avatarBytes;
  final VoidCallback? onEdit;
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final placeholder = const ColoredBox(
      color: HomeColors.selected,
      child: Center(
        child: Icon(Icons.person_rounded, color: ProfileTheme.muted, size: 54),
      ),
    );
    final url = profile.avatarUrl;
    final avatar = avatarBytes != null
        ? Image.memory(
            avatarBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
          )
        : url != null && url.isNotEmpty
        ? Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
          )
        : placeholder;
    return Column(
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ProfileTheme.orange, width: 2),
                  ),
                  child: ClipOval(child: avatar),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton.filled(
                  tooltip: 'Sửa ảnh đại diện',
                  style: IconButton.styleFrom(
                    backgroundColor: ProfileTheme.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onEditAvatar,
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.fullName.isEmpty ? 'Hồ sơ của bạn' : profile.fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          profile.phoneNumber.isEmpty
              ? 'Chưa cập nhật số điện thoại'
              : profile.phoneNumber,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ProfileTheme.muted, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: ProfileTheme.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ProfileTheme.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: ProfileTheme.gold,
                size: 20,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  profile.memberTier,
                  style: const TextStyle(
                    color: ProfileTheme.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Chỉnh sửa hồ sơ'),
          style: TextButton.styleFrom(foregroundColor: ProfileTheme.orange),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.onEdit,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: ProfileTheme.orange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: ProfileTheme.orange,
                  ),
                  child: const Text('Chỉnh sửa'),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: HomeColors.border),
          ),
          ...children,
        ],
      ),
    ),
  );
}

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: ProfileTheme.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: ProfileTheme.muted, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Chưa cập nhật' : value,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
