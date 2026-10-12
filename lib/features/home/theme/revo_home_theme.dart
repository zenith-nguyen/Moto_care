import 'package:flutter/material.dart';

import 'home_theme.dart';

abstract final class RevoHomeColors {
  static const background = Colors.white;
  static const ink = Color(0xFF111111);
  static const dark = Color(0xFF1C1C1E);
  static const muted = Color(0xFF77777C);
  static const surface = Color(0xFFF5F5F7);
  static const border = Color(0xFFE8E8EB);
  static const verified = Color(0xFF2784E8);
  static const navigationSelected = Color(0xFF3478D4);
  static const navigationSelectedBackground = Color(0xFFEAF1FC);
}

abstract final class RevoHomeTheme {
  static final light = HomeTheme.light.copyWith(
    scaffoldBackgroundColor: RevoHomeColors.background,
    colorScheme: HomeTheme.light.colorScheme.copyWith(
      primary: RevoHomeColors.ink,
      onPrimary: Colors.white,
      secondary: RevoHomeColors.ink,
      surface: Colors.white,
      onSurface: RevoHomeColors.ink,
      error: RevoHomeColors.ink,
      outline: RevoHomeColors.border,
    ),
    textTheme: HomeTheme.light.textTheme.apply(
      bodyColor: RevoHomeColors.ink,
      displayColor: RevoHomeColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: RevoHomeColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: RevoHomeColors.ink),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RevoHomeColors.ink,
        side: const BorderSide(color: RevoHomeColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RevoHomeColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: RevoHomeColors.ink),
      ),
    ),
  );
}
