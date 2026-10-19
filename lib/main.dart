import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/terms_and_commitment_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  // Restore the saved demo-orders switch first, so the Orders tab never flashes
  // the wrong list.
  await appState.restorePreferences();
  runApp(const RevoMechanicApp());
}

class RevoMechanicApp extends StatelessWidget {
  const RevoMechanicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REVO · Dành cho Thợ',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const TermsEntryScreen(),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: child!,
            ),
          )),
    );
  }
}
