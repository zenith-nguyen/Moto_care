import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_theme.dart';
import 'admin_typography.dart';

abstract final class AdminTheme {
  static final ThemeData light = _build();
  static const dashboardCardRadius = BorderRadius.all(Radius.circular(24));
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
    letterSpacing: AdminTypography.titleSpacing,
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
    final textTheme = AdminTypography.textTheme(AppTheme.light.textTheme)
        .apply(bodyColor: AdminTokens.text, displayColor: AdminTokens.text);
    final controlLabel = GoogleFonts.montserrat(
      textStyle: textTheme.bodyLarge,
      fontWeight: FontWeight.w500,
      letterSpacing: AdminTypography.bodySpacing,
    );
    final controlButton = GoogleFonts.montserrat(
      textStyle: textTheme.labelLarge,
      fontWeight: FontWeight.w600,
      letterSpacing: AdminTypography.actionSpacing,
    );
    return AppTheme.light.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AdminTokens.background,
      textTheme: textTheme,
      primaryTextTheme: AdminTypography.textTheme(
        AppTheme.light.primaryTextTheme,
      ),
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
        labelStyle: controlLabel,
        floatingLabelStyle: controlLabel,
        hintStyle: textTheme.bodyLarge?.copyWith(color: AdminTokens.muted),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
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
          textStyle: AdminTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AdminTokens.primaryBlue,
          textStyle: controlButton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            AppTheme.light.outlinedButtonTheme.style?.copyWith(
              textStyle: WidgetStatePropertyAll(controlButton),
            ) ??
            OutlinedButton.styleFrom(textStyle: controlButton),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            AppTheme.light.elevatedButtonTheme.style?.copyWith(
              textStyle: WidgetStatePropertyAll(controlButton),
            ) ??
            ElevatedButton.styleFrom(textStyle: controlButton),
      ),
      chipTheme: AppTheme.light.chipTheme.copyWith(
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge,
      ),
      tabBarTheme: AppTheme.light.tabBarTheme.copyWith(
        labelStyle: controlButton,
        unselectedLabelStyle: controlButton,
      ),
      dataTableTheme: AppTheme.light.dataTableTheme.copyWith(
        headingTextStyle: textTheme.labelLarge,
        dataTextStyle: textTheme.bodyMedium,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AdminTokens.surface,
        selectedIconTheme: IconThemeData(color: AdminTokens.primaryBlue),
        selectedLabelTextStyle: AdminTypography.label.copyWith(
          color: AdminTokens.primaryBlue,
        ),
        unselectedLabelTextStyle: AdminTypography.label.copyWith(
          color: AdminTokens.muted,
        ),
      ),
    );
  }
}
