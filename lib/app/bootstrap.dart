import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/notifications/firebase_push_token_source.dart';
import '../features/auth/domain/app_user.dart';
import 'app_dependencies.dart';
import 'moto_care_app.dart';
import 'provider_moto_care_app.dart';

enum AppRuntimeRole { customer, provider }

AppRuntimeRole resolveRuntimeRole({
  required AppRuntimeRole fallback,
  String? flavor,
}) {
  return switch (flavor?.trim().toLowerCase()) {
    'customer' => AppRuntimeRole.customer,
    'provider' => AppRuntimeRole.provider,
    _ => fallback,
  };
}

/// Boots the correct role UI from the Android flavor even if a developer
/// accidentally supplies the other Dart target to `flutter run`.
Future<void> bootstrapMotoCare(AppRuntimeRole fallback) async {
  WidgetsFlutterBinding.ensureInitialized();
  final pushTokens = await FirebasePushTokenSource.initialize(
    AppConfig.fromEnvironment(),
  );
  final role = resolveRuntimeRole(fallback: fallback, flavor: appFlavor);
  final allowedRoles = role == AppRuntimeRole.provider
      ? const <AppRole>{AppRole.provider}
      : const <AppRole>{AppRole.customer, AppRole.admin};

  runApp(
    ProviderScope(
      overrides: [
        pushTokenSourceProvider.overrideWithValue(pushTokens),
        runtimeApiIntegrationProvider.overrideWithValue(true),
        runtimeAllowedRolesProvider.overrideWithValue(allowedRoles),
      ],
      child: role == AppRuntimeRole.provider
          ? const ProviderMotoCareApp()
          : const MotoCareApp(),
    ),
  );
}
