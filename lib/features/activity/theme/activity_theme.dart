import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

abstract final class ActivityTheme {
  static const background = HomeColors.background;
  static const surface = HomeColors.surface;
  static const navigationSurface = HomeColors.surface;
  static const red = HomeColors.red;
  static const orange = HomeColors.primary;
  static const green = Color(0xFF218653);
  static const mutedText = HomeColors.secondary;

  static final light = HomeTheme.light.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: HomeTheme.light.colorScheme.copyWith(
      primary: orange,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: HomeColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: HomeColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
      ),
    ),
  );
}
