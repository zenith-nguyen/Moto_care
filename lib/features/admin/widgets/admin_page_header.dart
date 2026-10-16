import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import '../providers/admin_account_provider.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.fontSize = 22,
    this.onBack,
    this.showActions = true,
  });

  final String title;
  final double fontSize;
  final VoidCallback? onBack;
  final bool showActions;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (onBack != null) ...[
        IconButton(
          key: const ValueKey('admin-order-back'),
          tooltip: 'Quay lại danh sách đơn',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: AdminTokens.text),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: AdminTheme.pageTitleStyle.copyWith(fontSize: fontSize),
            ),
          ),
        ),
      ),
      if (showActions) ...[
        const SizedBox(width: 12),
        const _AdminHeaderActions(),
      ],
    ],
  );
}

class _AdminHeaderActions extends ConsumerWidget {
  const _AdminHeaderActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(adminSessionProvider)?.isAdmin != true) {
      return const SizedBox.shrink();
    }
    final counts = ref.watch(adminPendingCountsProvider);
    final avatar = ref.watch(
      adminAccountProvider.select((state) => state.avatarBytes),
    );
    final hasPending = (counts.asData?.value.total ?? 0) > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('admin-header-notifications'),
          tooltip: 'Thông báo',
          onPressed: () => context.go('/admin/requests'),
          style: IconButton.styleFrom(
            backgroundColor: AdminTokens.card,
            foregroundColor: AdminTokens.text,
            minimumSize: const Size(44, 44),
            shape: const CircleBorder(),
          ),
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 24),
                if (hasPending)
                  const Positioned(
                    top: 1,
                    right: 2,
                    child: DecoratedBox(
                      key: ValueKey('admin-header-notification-dot'),
                      decoration: BoxDecoration(
                        color: AdminTokens.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 7, height: 7),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const ValueKey('admin-header-account'),
          tooltip: 'Hồ sơ Admin',
          onPressed: () => context.go('/admin/account'),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: CircleAvatar(
            radius: 20,
            backgroundColor: AdminTokens.inactivePill,
            backgroundImage: avatar == null ? null : MemoryImage(avatar),
            child: avatar == null
                ? const Icon(
                    Icons.person_outline_rounded,
                    color: AdminTokens.inactivePillText,
                    size: 24,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
