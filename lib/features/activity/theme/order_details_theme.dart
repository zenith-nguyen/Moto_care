import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

abstract final class OrderDetailsTheme {
  static const red = Color(0xFFE53935);
  static const redTint = Color(0xFFFFEBEE);
  static const surface = Color(0xFFF8F9FA);
  static const text = Color(0xFF171717);
  static const muted = Color(0xFF747880);
  static const line = Color(0xFFE4E6E8);

  static final light = AppTheme.light.copyWith(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: text,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: red,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
