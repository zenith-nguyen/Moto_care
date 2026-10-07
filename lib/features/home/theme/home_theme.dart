import 'package:flutter/material.dart';

abstract final class HomeColors {
  static const background = Color(0xFFF8F9FA);
  static const surface = Colors.white;
  static const primary = Color(0xFFFF6B35);
  static const text = Color(0xFF202020);
  static const secondary = Color(0xFF707070);
  static const red = Color(0xFFE53935);
  static const selected = Color(0xFFFFF0EC);
  static const border = Color(0xFFEEEEEE);

  static final shadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
}

abstract final class HomeTheme {
  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: HomeColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HomeColors.primary,
      brightness: Brightness.light,
      primary: HomeColors.primary,
      onPrimary: Colors.white,
      surface: HomeColors.surface,
      onSurface: HomeColors.text,
    ),
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Roboto',
      bodyColor: HomeColors.text,
      displayColor: HomeColors.text,
    ),
    dividerTheme: const DividerThemeData(
      color: HomeColors.border,
      thickness: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HomeColors.surface,
      foregroundColor: HomeColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: HomeColors.text,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HomeColors.text,
        side: const BorderSide(color: HomeColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: HomeColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HomeColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: HomeColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: HomeColors.primary),
    ),
  );
}
