import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import '../providers/admin_providers.dart';
import '../theme/admin_theme.dart';
import 'admin_common.dart';
import 'admin_floating_bottom_nav.dart';

class AdminNavigationShell extends ConsumerWidget {
  const AdminNavigationShell({
    super.key,
    required this.child,
    required this.location,
  });
  final Widget child;
  final String location;
  static const _destinations = [
    ('Tổng quan', Icons.dashboard_outlined, '/admin/dashboard'),
    ('Đơn hàng', Icons.receipt_long_outlined, '/admin/orders'),
    ('Duyệt thợ', Icons.verified_user_outlined, '/admin/providers'),
    ('Tài chính', Icons.account_balance_outlined, '/admin/finance'),
    ('Xử lý yêu cầu', Icons.assignment_outlined, '/admin/requests'),
    ('Tài khoản', Icons.manage_accounts_outlined, '/admin/account'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(adminSessionProvider);
    final allowed = session?.isAdmin == true;
    return Theme(
      data: AdminTheme.light,
      child: Builder(
        builder: (context) {
          if (!allowed) {
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AdminStateView.forbidden(),
                        FilledButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Đăng nhập'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final counts = ref.watch(adminPendingCountsProvider);
          var selected = _destinations.indexWhere(
            (d) => location == d.$3 || location.startsWith('${d.$3}/'),
          );
          if (selected < 0) selected = 0;
          Widget icon(int index) {
            final widget = Icon(_destinations[index].$2);
            if (index != 4) return widget;
            final count = counts.asData?.value.total;
            return Tooltip(
              message: counts.hasError
                  ? 'Không thể tải số yêu cầu chờ. Mở danh sách để thử lại.'
                  : count == null
                  ? 'Đang tải số yêu cầu'
                  : '$count yêu cầu đang chờ',
              child: Badge(
                backgroundColor: AdminTokens.primaryRed,
                isLabelVisible: count == null || count > 0,
                label: Text(
                  count == null ? (counts.hasError ? '!' : '…') : '$count',
                ),
                child: widget,
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1100;
              final rail = constraints.maxWidth >= 760;
              final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.2;
              return Scaffold(
                backgroundColor: AdminTokens.background,
                extendBody: !rail,
                body: SafeArea(
                  bottom: rail,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (rail)
                        NavigationRail(
                          extended: wide && !largeText,
                          labelType: wide && !largeText
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.selected,
                          selectedIndex: selected,
                          minExtendedWidth: 230,
                          onDestinationSelected: (index) =>
                              context.go(_destinations[index].$3),
                          destinations: [
                            for (var i = 0; i < _destinations.length; i++)
                              NavigationRailDestination(
                                icon: icon(i),
                                label: Text(_destinations[i].$1),
                              ),
                          ],
                        ),
                      if (rail) const VerticalDivider(width: 1),
                      Expanded(child: child),
                    ],
                  ),
                ),
                bottomNavigationBar: rail
                    ? null
                    : AdminFloatingBottomNav(
                        selectedIndex: selected,
                        requestIcon: icon(4),
                        onSelected: (index) =>
                            context.go(_destinations[index].$3),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
