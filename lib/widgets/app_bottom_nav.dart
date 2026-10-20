import 'package:flutter/material.dart';

import '../screens/mechanic_account_screen.dart';
import '../screens/mechanic_home_screen.dart';
import '../screens/mechanic_wallet_screen.dart';
import '../screens/order_history_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Floating capsule dock shared by every main tab (reserved by Scaffold, so it
/// never covers content and never spans the full width of the screen).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    this.inactiveLabelWeight = FontWeight.w400,
  });
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final FontWeight inactiveLabelWeight;
  static const _items = <(String, IconData, IconData)>[
    ('Trang chủ', Icons.home_outlined, Icons.home_rounded),
    ('Đơn hàng', Icons.assignment_outlined, Icons.assignment_rounded),
    (
      'Ví',
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet_rounded,
    ),
    ('Tài khoản', Icons.person_outline_rounded, Icons.person_rounded),
  ];
  static const _inactive = Color(0xFF71839E);
  static const _radius = 36.0;

  @override
  Widget build(BuildContext context) => Padding(
        // Side margins plus a gap *above* the system gesture area (inset + 10).
        padding: EdgeInsets.fromLTRB(
            14, 6, 14, MediaQuery.viewPaddingOf(context).bottom + 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: const Color(0xFFE3EAF3), width: .8),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14172638),
                  blurRadius: 22,
                  offset: Offset(0, 6)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_radius),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        label: _items[i].$1,
                        icon: i == currentIndex ? _items[i].$3 : _items[i].$2,
                        active: i == currentIndex,
                        inactiveLabelWeight: inactiveLabelWeight,
                        onTap: () => onChanged(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    required this.inactiveLabelWeight,
  });
  final String label;
  final IconData icon;
  final bool active;
  final FontWeight inactiveLabelWeight;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppBottomNav._inactive;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                key: ValueKey('nav-pill-$label'),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 46,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFEAF4FC) : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w600 : inactiveLabelWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung giao diện Thợ: 4 tab giữ nguyên trạng thái (IndexedStack) + bottom nav.
class MechanicShell extends StatelessWidget {
  const MechanicShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) => Scaffold(
        backgroundColor: appState.tabIndex == 0 ? Colors.white : AppColors.bg,
        body: IndexedStack(
          index: appState.tabIndex,
          children: const [
            MechanicHomeScreen(),
            OrderHistoryScreen(),
            MechanicWalletScreen(),
            MechanicAccountScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: appState.tabIndex,
          onChanged: appState.setTab,
        ),
      ),
    );
  }
}
