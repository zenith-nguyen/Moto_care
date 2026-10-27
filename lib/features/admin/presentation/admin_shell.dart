import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../auth/domain/app_user.dart';

/// Admin navigation shell: wraps every admin tab in the REVO floating bottom
/// navigation from the prototype so the console reads as one 6-tab app instead
/// of disconnected screens. The order-detail screen is pushed full-screen
/// outside this shell (no bottom bar), matching the prototype.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const destinations = <({String label, IconData icon, String route})>[
    (label: 'Tổng quan', icon: Icons.dashboard_outlined, route: '/admin'),
    (
      label: 'Đơn hàng',
      icon: Icons.receipt_long_outlined,
      route: '/admin/orders',
    ),
    (
      label: 'Duyệt thợ',
      icon: Icons.verified_user_outlined,
      route: '/admin/providers',
    ),
    (
      label: 'Tài chính',
      icon: Icons.account_balance_outlined,
      route: '/admin/reconciliation',
    ),
    (
      label: 'Xử lý yêu cầu',
      icon: Icons.assignment_outlined,
      route: '/admin/finance',
    ),
    (
      label: 'Tài khoản',
      icon: Icons.manage_accounts_outlined,
      route: '/admin/account',
    ),
  ];

  int _selectedIndex() {
    var selected = 0;
    var bestLength = -1;
    for (var i = 0; i < destinations.length; i++) {
      final route = destinations[i].route;
      final matches = location == route || location.startsWith('$route/');
      if (matches && route.length > bestLength) {
        bestLength = route.length;
        selected = i;
      }
    }
    return selected;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final isAdmin =
        session is SessionSignedIn &&
        session.session.user.role == AppRole.admin;
    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AdminTokens.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: AdminTokens.muted,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn không có quyền truy cập khu vực quản trị',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
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

    final selected = _selectedIndex();
    return Scaffold(
      backgroundColor: AdminTokens.background,
      body: child,
      bottomNavigationBar: _AdminBottomNav(
        selectedIndex: selected,
        onSelected: (index) => context.go(destinations[index].route),
      ),
    );
  }
}

/// The six icon-only admin destinations rendered as a floating rounded bar,
/// faithful to the REVO admin prototype.
class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AdminTokens.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
          BoxShadow(color: Color(0x08000000), blurRadius: 4),
        ],
      ),
      child: Material(
        color: AdminTokens.surface,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < AdminShell.destinations.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: selectedIndex == i,
                      label: AdminShell.destinations[i].label,
                      child: Tooltip(
                        message: AdminShell.destinations[i].label,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => onSelected(i),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: selectedIndex == i
                                  ? AdminTokens.activePill
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Center(
                              child: Icon(
                                AdminShell.destinations[i].icon,
                                size: 23,
                                color: selectedIndex == i
                                    ? AdminTokens.primaryBlue
                                    : AdminTokens.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
