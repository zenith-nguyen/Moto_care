import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_theme.dart';

abstract final class AdminTheme {
  static final ThemeData light = _build();
  static const dashboardCardRadius = BorderRadius.all(Radius.circular(20));
  static final dashboardCardDecoration = BoxDecoration(
    color: AdminTokens.card,
    borderRadius: dashboardCardRadius,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
  static final pageTitleStyle = GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AdminTokens.text,
    height: 1.3,
  );

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AdminTokens.primaryBlue,
      primary: AdminTokens.primaryBlue,
      error: AdminTokens.primaryRed,
      surface: AdminTokens.surface,
    );
    return AppTheme.light.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AdminTokens.background,
      textTheme: GoogleFonts.montserratTextTheme(AppTheme.light.textTheme)
          .apply(
            // Keep bundled weights in one family when a child overrides weight.
            fontFamily: 'Montserrat',
            bodyColor: AdminTokens.text,
            displayColor: AdminTokens.text,
          ),
      primaryTextTheme: GoogleFonts.montserratTextTheme(
        AppTheme.light.primaryTextTheme,
      ).apply(fontFamily: 'Montserrat'),
      dividerTheme: const DividerThemeData(color: AdminTokens.border),
      appBarTheme: AppBarTheme(
        backgroundColor: AdminTokens.surface,
        foregroundColor: AdminTokens.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: pageTitleStyle,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminTokens.surface,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminTokens.primaryBlue),
        ),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AdminTokens.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: AppTextStyles.status,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AdminTokens.primaryBlue),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AdminTokens.surface,
        selectedIconTheme: IconThemeData(color: AdminTokens.primaryBlue),
        selectedLabelTextStyle: AppTextStyles.caption.copyWith(
          color: AdminTokens.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: AppTextStyles.caption.copyWith(
          color: AdminTokens.muted,
        ),
      ),
    );
  }
}
