import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/mechanic_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  runApp(const MotoCareMechanicApp());
}

class MotoCareMechanicApp extends StatefulWidget {
  const MotoCareMechanicApp({super.key});

  @override
  State<MotoCareMechanicApp> createState() => _MotoCareMechanicAppState();
}

class _MotoCareMechanicAppState extends State<MotoCareMechanicApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AppScope đặt phía trên MaterialApp để mọi route/dialog/bottom sheet đều truy cập được.
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'MotoCare Thợ',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const MechanicShell(),
      ),
    );
  }
}
