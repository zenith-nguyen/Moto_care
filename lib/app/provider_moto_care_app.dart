import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/push_session_coordinator.dart';
import '../core/realtime/realtime_session_coordinator.dart';
import '../core/theme/revo_theme.dart';
import 'router/app_router.dart';

/// Provider-branded entrypoint that keeps the shared authenticated router,
/// repositories, REST snapshots, and Socket.IO session coordinator.
class ProviderMotoCareApp extends ConsumerWidget {
  const ProviderMotoCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(realtimeSessionCoordinatorProvider);
    ref.watch(pushSessionCoordinatorProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'REVO Thợ',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildRevoTheme(),
      routerConfig: router,
    );
  }
}
