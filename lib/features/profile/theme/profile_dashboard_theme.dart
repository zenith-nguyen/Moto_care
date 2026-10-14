import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';
import '../../home/theme/revo_home_theme.dart';

abstract final class ProfileDashboardTheme {
  static const primary = RevoHomeColors.navigationSelected;
  static const primaryContainer = RevoHomeColors.navigationSelectedBackground;
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF737373);
  static const background = Color(0xFFF8F9FA);
  static const border = Color(0xFFEEEEEE);

  static final light = HomeTheme.light.copyWith(
    colorScheme: HomeTheme.light.colorScheme.copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: primary,
      onSurface: ink,
      onSurfaceVariant: muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
  );
}
