import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/models/home_destination.dart';

const _mainTabPaths = {
  HomeDestination.home: '/trang-chu',
  HomeDestination.myVehicles: '/xe-cua-toi',
  HomeDestination.activity: '/hoat-dong',
  HomeDestination.rescueStations: '/tram-cuu-ho',
  HomeDestination.messages: '/tin-nhan',
  HomeDestination.services: '/dich-vu',
  HomeDestination.account: '/tai-khoan',
  HomeDestination.vouchers: '/kho-voucher',
};

Future<void> navigateMainTab(
  BuildContext context,
  HomeDestination destination,
) async {
  final path = _mainTabPaths[destination];
  final router = GoRouter.of(context);
  var currentPath = router.state.uri.path;
  if (path == null || currentPath == path) return;
  if (destination == HomeDestination.home) {
    await returnToHome(context);
  } else {
    // Leave a feature page before switching tabs so its parent tab is reused.
    while (HomeDestination.homeNavigationItems.contains(destination) &&
        !HomeDestination.homeNavigationItems.any(
          (item) => _mainTabPaths[item] == currentPath,
        ) &&
        router.canPop()) {
      router.pop();
      await WidgetsBinding.instance.endOfFrame;
      currentPath = router.state.uri.path;
    }
    if (currentPath == path) return;
    // Keep one secondary tab above Home instead of stacking repeated tabs.
    if (HomeDestination.homeNavigationItems.contains(destination) &&
        HomeDestination.homeNavigationItems.any(
          (item) => _mainTabPaths[item] == currentPath,
        ) &&
        currentPath != '/trang-chu') {
      router.replace(path);
    } else {
      router.push(path);
    }
  }
}

/// Preserve the existing home page and its account when returning from tabs.
Future<void> returnToHome(BuildContext context) async {
  final router = GoRouter.of(context);
  while (router.state.uri.path != '/trang-chu' && router.canPop()) {
    router.pop();
    // Let Navigator finish removing the page before popping the next one.
    await WidgetsBinding.instance.endOfFrame;
  }
  if (router.state.uri.path != '/trang-chu') router.go('/trang-chu');
}
