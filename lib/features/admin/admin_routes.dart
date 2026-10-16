import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'screens/admin_account_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_order_detail_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/admin_provider_approval_screen.dart';
import 'screens/admin_reconciliation_screen.dart';
import 'screens/admin_requests_processing_screen.dart';
import 'widgets/admin_navigation_shell.dart';

List<RouteBase> get adminRoutes => [
  GoRoute(path: '/admin', redirect: (context, state) => '/admin/dashboard'),
  ShellRoute(
    builder: (context, state, child) =>
        AdminNavigationShell(location: state.uri.path, child: child),
    routes: [
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/orders/:orderId',
        builder: (context, state) =>
            AdminOrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/admin/providers',
        builder: (context, state) => const AdminProviderApprovalScreen(),
      ),
      GoRoute(
        path: '/admin/finance',
        builder: (context, state) => const AdminReconciliationScreen(),
      ),
      GoRoute(
        path: '/admin/requests',
        builder: (context, state) => AdminRequestsProcessingScreen(
          key: ValueKey(state.uri.queryParameters['tab']),
          initialTab: state.uri.queryParameters['tab'] == 'withdrawals' ? 2 : 0,
        ),
      ),
      GoRoute(
        path: '/admin/account',
        builder: (context, state) => const AdminAccountScreen(),
      ),
    ],
  ),
];
