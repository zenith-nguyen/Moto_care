import 'package:flutter/material.dart';

import '../../../core/theme/revo_brand.dart';
import 'home_theme.dart';

abstract final class RevoHomeColors {
  static const background = Colors.white;
  static const primary = RevoBrandColors.primary;
  static const ink = RevoBrandColors.ink;
  static const dark = RevoBrandColors.navy;
  static const muted = RevoBrandColors.textSubtle;
  static const surface = Color(0xFFF5F5F7);
  static const border = RevoBrandColors.border;
  static const verified = Color(0xFF2784E8);
  static const navigationSelected = RevoBrandColors.primary;
  static const navigationSelectedBackground = RevoBrandColors.surfaceSoft;
}

abstract final class RevoHomeTheme {
  static final light = HomeTheme.light.copyWith(
    scaffoldBackgroundColor: RevoHomeColors.background,
    colorScheme: HomeTheme.light.colorScheme.copyWith(
      primary: RevoHomeColors.primary,
      onPrimary: Colors.white,
      secondary: RevoBrandColors.sky,
      surface: Colors.white,
      onSurface: RevoHomeColors.ink,
      error: RevoBrandColors.dangerDark,
      outline: RevoHomeColors.border,
    ),
    textTheme: HomeTheme.light.textTheme.apply(
      bodyColor: RevoHomeColors.ink,
      displayColor: RevoHomeColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: RevoHomeColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: RevoHomeColors.primary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RevoHomeColors.primary,
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
        borderSide: const BorderSide(color: RevoHomeColors.primary),
      ),
    ),
  );
}
