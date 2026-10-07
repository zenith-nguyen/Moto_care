import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

abstract final class ProfileTheme {
  static const background = HomeColors.background;
  static const surface = HomeColors.surface;
  static const red = HomeColors.red;
  static const orange = HomeColors.primary;
  static const gold = HomeColors.primary;
  static const muted = HomeColors.secondary;

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
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HomeColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(color: muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
      ),
    ),
  );
}
