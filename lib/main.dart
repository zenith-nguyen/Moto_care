import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/mechanic_login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  runApp(const MotoCareMechanicApp());
}

class MotoCareMechanicApp extends StatelessWidget {
  const MotoCareMechanicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoCare Thợ',
      debugShowCheckedModeBanner: false,
      // Font Montserrat qua GoogleFonts.montserratTextTheme() (xem buildAppTheme).
      theme: buildAppTheme(),
      home: const MechanicLoginScreen(),
    );
  }
}
