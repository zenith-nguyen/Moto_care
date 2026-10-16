import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'admin_routes.dart';
import 'models/admin_models.dart';
import 'providers/admin_providers.dart';
import 'theme/admin_theme.dart';
import 'widgets/admin_common.dart';

/// Explicit development entry point, never enabled by the customer login.
void main() => runApp(
  ProviderScope(
    overrides: [
      adminSessionProvider.overrideWith(
        () => AdminSessionController(
          initialSession: const AdminSession(
            id: 'ADM-2026-88',
            name: 'Quản trị viên',
            email: 'admin@revo.vn',
            role: 'ADMIN',
            canManageAdmins: true,
          ),
        ),
      ),
    ],
    child: const AdminPreviewApp(),
  ),
);

class AdminPreviewApp extends StatefulWidget {
  const AdminPreviewApp({super.key});
  @override
  State<AdminPreviewApp> createState() => _AdminPreviewAppState();
}

class _AdminPreviewAppState extends State<AdminPreviewApp> {
  final _router = GoRouter(
    initialLocation: '/admin/dashboard',
    routes: [
      ...adminRoutes,
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: AdminStateView(
              title: 'Đã đăng xuất preview Admin',
              icon: Icons.logout,
              description:
                  'Khởi động lại preview để bắt đầu phiên sandbox mới.',
            ),
          ),
        ),
      ),
    ],
  );
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Revo Admin • Sandbox',
    debugShowCheckedModeBanner: false,
    theme: AdminTheme.light,
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: _router,
  );
}
