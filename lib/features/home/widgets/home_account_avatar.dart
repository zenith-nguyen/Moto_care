import 'package:flutter/material.dart';

import '../../profile/models/profile_state.dart';

class HomeAccountAvatar extends StatelessWidget {
  const HomeAccountAvatar({
    super.key,
    required this.profile,
    required this.onTap,
    this.placeholder = false,
  });
  final ProfileState profile;
  final VoidCallback onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(
      Icons.person_outline_rounded,
      size: 25,
      color: Color(0xFF171717),
    );
    final avatar = placeholder
        ? const SizedBox.shrink()
        : profile.avatarBytes != null
        ? Image.memory(
            profile.avatarBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : profile.profile.avatarUrl?.isNotEmpty == true
        ? Image.network(
            profile.profile.avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : fallback;
    return Tooltip(
      message: profile.profile.fullName.isEmpty
          ? 'Tài khoản của bạn'
          : 'Tài khoản ${profile.profile.fullName}',
      child: Semantics(
        label: 'Mở tài khoản',
        button: true,
        child: Material(
          color: placeholder
              ? const Color(0xFFF1F4F7)
              : const Color(0xFFE6DDFA),
          shape: CircleBorder(
            side: placeholder
                ? const BorderSide(color: Color(0xFFE1E7ED))
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('home-avatar'),
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(width: 44, height: 44, child: avatar),
          ),
        ),
      ),
    );
  }
}
