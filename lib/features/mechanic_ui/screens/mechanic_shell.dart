import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/app_bottom_nav.dart';
import 'mechanic_home_screen.dart';
import 'mechanic_profile_screen.dart';
import 'mechanic_wallet_screen.dart';

/// Khung chính với bottom nav 3 tab: Trang chủ / Ví / Hồ sơ.
class MechanicShell extends StatelessWidget {
  const MechanicShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: IndexedStack(
        index: state.tabIndex,
        children: const [
          MechanicHomeScreen(),
          MechanicWalletScreen(),
          MechanicProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: state.tabIndex,
        onChanged: state.setTab,
      ),
    );
  }
}
