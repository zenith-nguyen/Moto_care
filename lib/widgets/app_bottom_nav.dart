import 'package:flutter/material.dart';

import '../screens/mechanic_account_screen.dart';
import '../screens/mechanic_home_screen.dart';
import '../screens/mechanic_wallet_screen.dart';
import '../screens/order_history_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Bottom nav dùng chung: tab active icon + chữ đen đậm, tab thường xám.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = <(String, IconData, IconData)>[
    ('Trang chủ', Icons.home_outlined, Icons.home),
    ('Đơn hàng', Icons.layers_outlined, Icons.layers),
    ('Ví', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
    ('Tài khoản', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFEFF1))),
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
                    icon: i == currentIndex ? _items[i].$3 : _items[i].$2,
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
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.ink : AppColors.textMuted;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appText(
                  12,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
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
