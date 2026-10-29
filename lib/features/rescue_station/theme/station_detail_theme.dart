import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

abstract final class StationDetailColors {
  static const red = Color(0xFFE53935);
  static const redTint = Color(0xFFFFEFEE);
  static const catalogTint = Color(0xFFFFEBEE);
  static const catalogBorder = Color(0xFFEEEEEE);
  static const text = Color(0xFF171717);
  static const muted = Color(0xFF85858B);
  static const surface = Color(0xFFF8F9FA);
  static const border = Color(0xFFF0F0F2);
  static const green = Color(0xFF29945D);
  static const verified = Color(0xFF2685E8);
  static const yellow = Color(0xFFFFC107);
}

abstract final class StationDetailTheme {
  static final light = HomeTheme.light.copyWith(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: HomeTheme.light.colorScheme.copyWith(
      primary: StationDetailColors.red,
      onPrimary: Colors.white,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: StationDetailColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Montserrat',
        color: StationDetailColors.text,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
