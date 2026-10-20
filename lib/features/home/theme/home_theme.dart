import 'package:flutter/material.dart';

import '../../../core/theme/revo_brand.dart';

abstract final class HomeColors {
  static const background = Color(0xFFF8F9FA);
  static const surface = Colors.white;
  static const primary = RevoBrandColors.primary;
  static const text = RevoBrandColors.ink;
  static const secondary = RevoBrandColors.textSubtle;
  static const danger = RevoBrandColors.danger;
  static const dangerDark = RevoBrandColors.dangerDark;
  static const red = primary;
  // Keep the legacy aliases while all role apps migrate to shared tokens.
  static const tint = RevoBrandColors.surfaceSoft;
  static const selected = Color(0x24317CBB);
  static const tintStrong = Color(0x36317CBB);
  static const accentBorder = Color(0x66317CBB);
  static const redSelected = selected;
  static const border = RevoBrandColors.border;

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
    fontFamily: 'Montserrat',
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
      error: HomeColors.dangerDark,
      onError: Colors.white,
      errorContainer: RevoBrandColors.dangerSoft,
      onErrorContainer: HomeColors.dangerDark,
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
      fontFamily: 'Montserrat',
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
      labelStyle: const TextStyle(
        fontFamily: 'Montserrat',
        color: HomeColors.text,
      ),
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
        fontFamily: 'Montserrat',
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
