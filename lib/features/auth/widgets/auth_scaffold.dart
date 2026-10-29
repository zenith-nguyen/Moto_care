import 'package:flutter/material.dart';

import '../theme/auth_theme.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, this.appBar, required this.body});

  final PreferredSizeWidget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) => Theme(
    data: AuthTheme.light,
    child: Scaffold(
      backgroundColor: AuthColors.background,
      appBar: appBar,
      body: body,
    ),
  );
}
