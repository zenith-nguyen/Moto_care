import 'package:flutter/material.dart';

abstract final class HomeColors {
  static const background = Color(0xFFF8F9FA);
  static const surface = Colors.white;
  static const primary = Color(0xFFCC0001);
  static const text = Color(0xFF111827);
  static const secondary = Color(0xFF4B5563);
  static const red = primary;
  // Keep subtle backgrounds and borders in the same brand color.
  static const tint = Color(0x0ACC0001);
  static const selected = Color(0x14CC0001);
  static const tintStrong = Color(0x26CC0001);
  static const accentBorder = Color(0x33CC0001);
  static const redSelected = selected;
  static const border = Color(0xFFEEEEEE);

  static final shadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
}

abstract final class HomeTheme {
  static final light = _createLight(HomeColors.primary);
  static final red = _createLight(HomeColors.red);

  static ThemeData _createLight(Color accentColor) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: HomeColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.light,
      primary: accentColor,
      onPrimary: Colors.white,
      primaryContainer: HomeColors.selected,
      onPrimaryContainer: accentColor,
      primaryFixed: HomeColors.selected,
      primaryFixedDim: HomeColors.tintStrong,
      onPrimaryFixed: accentColor,
      onPrimaryFixedVariant: accentColor,
      secondary: accentColor,
      onSecondary: Colors.white,
      secondaryContainer: HomeColors.selected,
      onSecondaryContainer: accentColor,
      secondaryFixed: HomeColors.selected,
      secondaryFixedDim: HomeColors.tintStrong,
      onSecondaryFixed: accentColor,
      onSecondaryFixedVariant: accentColor,
      tertiary: accentColor,
      onTertiary: Colors.white,
      tertiaryContainer: HomeColors.selected,
      onTertiaryContainer: accentColor,
      tertiaryFixed: HomeColors.selected,
      tertiaryFixedDim: HomeColors.tintStrong,
      onTertiaryFixed: accentColor,
      onTertiaryFixedVariant: accentColor,
      error: accentColor,
      onError: Colors.white,
      errorContainer: HomeColors.selected,
      onErrorContainer: accentColor,
      surface: HomeColors.surface,
      surfaceDim: HomeColors.background,
      surfaceBright: HomeColors.surface,
      onSurface: HomeColors.text,
      onSurfaceVariant: HomeColors.secondary,
      outline: HomeColors.border,
      outlineVariant: HomeColors.border,
      surfaceContainerLowest: HomeColors.surface,
      surfaceContainerLow: HomeColors.surface,
      surfaceContainer: HomeColors.background,
      surfaceContainerHigh: HomeColors.background,
      surfaceContainerHighest: HomeColors.background,
      inverseSurface: HomeColors.text,
      onInverseSurface: Colors.white,
      inversePrimary: accentColor,
      surfaceTint: Colors.transparent,
    ),
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Roboto',
      bodyColor: HomeColors.text,
      displayColor: HomeColors.text,
    ),
    iconTheme: const IconThemeData(color: HomeColors.text),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      selectedColor: HomeColors.redSelected,
      checkmarkColor: HomeColors.red,
      labelStyle: const TextStyle(fontFamily: 'Roboto', color: HomeColors.text),
      side: const BorderSide(color: HomeColors.border),
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
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accentColor),
    ),
  );
}
