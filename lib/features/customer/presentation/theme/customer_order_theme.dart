import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../activity/models/rescue_order.dart';

/// Fintech presentation shared by customer order details and live tracking.
abstract final class CustomerOrderTheme {
  static const navy = Color(0xFF0F172A);
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const warningTint = Color(0xFFFFEDD5);
  static const warningText = Color(0xFF9A3412);
  static const successTint = Color(0xFFDCFCE7);
  static const successText = Color(0xFF166534);
  static const shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
  ];
  static const cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    boxShadow: shadow,
  );

  static TextStyle text({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = navy,
    double height = 1.4,
  }) => GoogleFonts.montserrat(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: -0.3,
  );

  static ({Color background, Color foreground}) statusColors(
    RescueOrderStatus status,
  ) => switch (status) {
    RescueOrderStatus.pending || RescueOrderStatus.enRoute => (
      background: warningTint,
      foreground: warningText,
    ),
    RescueOrderStatus.repairing => (
      background: const Color(0xFFDBEAFE),
      foreground: const Color(0xFF1E40AF),
    ),
    RescueOrderStatus.completed => (
      background: successTint,
      foreground: successText,
    ),
    RescueOrderStatus.cancelled => (background: line, foreground: muted),
  };

  static TextTheme _textTheme(TextTheme base) {
    TextStyle role(TextStyle? style) => GoogleFonts.montserrat(
      textStyle: style,
      color: navy,
      letterSpacing: -0.3,
    );
    return TextTheme(
      displayLarge: role(base.displayLarge),
      displayMedium: role(base.displayMedium),
      displaySmall: role(base.displaySmall),
      headlineLarge: role(base.headlineLarge),
      headlineMedium: role(base.headlineMedium),
      headlineSmall: role(base.headlineSmall),
      titleLarge: role(base.titleLarge),
      titleMedium: role(base.titleMedium),
      titleSmall: role(base.titleSmall),
      bodyLarge: role(base.bodyLarge),
      bodyMedium: role(base.bodyMedium),
      bodySmall: role(base.bodySmall),
      labelLarge: role(base.labelLarge),
      labelMedium: role(base.labelMedium),
      labelSmall: role(base.labelSmall),
    );
  }

  static final light = AppTheme.light.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: AppTheme.light.colorScheme.copyWith(
      primary: navy,
      onPrimary: Colors.white,
      secondary: navy,
      surface: surface,
      onSurface: navy,
      outline: line,
      outlineVariant: line,
    ),
    textTheme: _textTheme(AppTheme.light.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: navy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: text(fontSize: 18, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: text(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        side: const BorderSide(color: line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: text(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: muted,
        textStyle: text(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: navy),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
