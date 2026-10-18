import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.fontSize = 22,
    this.fontWeight,
    this.onBack,
    this.leading,
    this.showNotifications = false,
    this.centerTitle = false,
  });

  final String title;
  final double fontSize;
  final FontWeight? fontWeight;
  final VoidCallback? onBack;
  final Widget? leading;
  final bool showNotifications;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: centerTitle
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      if (leading != null) ...[
        leading!,
        const SizedBox(width: 12),
      ] else if (centerTitle && onBack == null && showNotifications)
        const SizedBox(width: 56),
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
              textAlign: centerTitle ? TextAlign.center : TextAlign.left,
              style: AdminTheme.pageTitleStyle.copyWith(
                fontFamily: fontWeight == null ? null : 'Montserrat',
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
        ),
      ),
      if (centerTitle && onBack != null && !showNotifications)
        const SizedBox(width: 56),
      if (showNotifications) ...[
        const SizedBox(width: 12),
        const _AdminHeaderNotifications(),
      ],
    ],
  );
}

class _AdminHeaderNotifications extends ConsumerWidget {
  const _AdminHeaderNotifications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(adminSessionProvider)?.isAdmin != true) {
      return const SizedBox.shrink();
    }
    final counts = ref.watch(adminPendingCountsProvider);
    final hasPending = (counts.asData?.value.total ?? 0) > 0;
    return IconButton(
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
    );
  }
}
