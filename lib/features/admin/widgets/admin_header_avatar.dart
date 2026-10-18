import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_account_provider.dart';

class AdminHeaderAvatar extends ConsumerWidget {
  const AdminHeaderAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(
      adminAccountProvider.select((state) => state.avatarBytes),
    );
    return Tooltip(
      message: 'Tài khoản Admin',
      child: Semantics(
        label: 'Mở tài khoản Admin',
        button: true,
        child: Material(
          color: const Color(0xFFF1F4F7),
          shape: const CircleBorder(side: BorderSide(color: Color(0xFFE1E7ED))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('admin-header-avatar'),
            onTap: () => context.go('/admin/account'),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: bytes == null
                  ? const SizedBox.shrink()
                  : Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
