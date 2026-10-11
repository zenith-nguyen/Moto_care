import 'package:flutter/material.dart';

import '../screens/mechanic_account_screen.dart';
import '../screens/mechanic_home_screen.dart';
import '../screens/mechanic_wallet_screen.dart';
import '../screens/order_history_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Bottom nav dùng chung: tab active nền đen bo tròn + icon/text trắng, tab thường xám.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = <(String, IconData)>[
    ('Trang chủ', Icons.home_outlined),
    ('Đơn hàng', Icons.receipt_long_outlined),
    ('Ví', Icons.credit_card_outlined),
    ('Tài khoản', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    label: _items[i].$1,
                    icon: _items[i].$2,
                    active: i == currentIndex,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.label, required this.icon, required this.active, required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppColors.textMuted;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    appText(11.5, weight: active ? FontWeight.w800 : FontWeight.w600, color: color),
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
