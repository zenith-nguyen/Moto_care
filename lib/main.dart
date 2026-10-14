import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_dependencies.dart';
import 'app/moto_care_app.dart';
import 'core/config/app_config.dart';
import 'core/notifications/firebase_push_token_source.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pushTokens = await FirebasePushTokenSource.initialize(
    AppConfig.fromEnvironment(),
  );
  runApp(
    ProviderScope(
      overrides: [pushTokenSourceProvider.overrideWithValue(pushTokens)],
      child: const MotoCareApp(),
    ),
  );
}
