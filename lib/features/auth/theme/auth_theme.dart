import 'package:flutter/material.dart';

import '../../../core/theme/revo_brand.dart';
import '../../../core/theme/app_theme.dart';

abstract final class AuthColors {
  static const primary = RevoBrandColors.primary;
  static const text = RevoBrandColors.ink;
  static const secondary = RevoBrandColors.textSubtle;
  static const background = Colors.white;
  static const field = Color(0xFFF5F5F5);
  static const border = Color(0xFFE0E0E0);
  static const disabled = Color(0xFFE5E5E5);
}

abstract final class AuthTheme {
  static final light = AppTheme.light.copyWith(
    scaffoldBackgroundColor: AuthColors.background,
    colorScheme: AppTheme.light.colorScheme.copyWith(
      primary: AuthColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AuthColors.field,
      secondary: AuthColors.primary,
      onSecondary: Colors.white,
      surface: AuthColors.background,
      onSurface: AuthColors.text,
      error: RevoBrandColors.dangerDark,
      onError: Colors.white,
      outline: AuthColors.border,
    ),
    textTheme: AppTheme.light.textTheme.apply(
      bodyColor: AuthColors.text,
      displayColor: AuthColors.text,
    ),
    appBarTheme: AppTheme.light.appBarTheme.copyWith(
      backgroundColor: AuthColors.background,
      foregroundColor: AuthColors.text,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTheme.light.appBarTheme.titleTextStyle?.copyWith(
        color: AuthColors.text,
      ),
    ),
    inputDecorationTheme: AppTheme.light.inputDecorationTheme.copyWith(
      fillColor: AuthColors.field,
      hintStyle: const TextStyle(color: AuthColors.secondary, fontSize: 18),
      errorStyle: const TextStyle(color: AuthColors.text),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthColors.primary),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthColors.primary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AuthColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AuthColors.disabled,
        disabledForegroundColor: AuthColors.secondary,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AuthColors.primary,
        textStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AuthColors.primary,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AuthColors.border),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
