import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

abstract final class OrderSummaryColors {
  static const red = Color(0xFFE53935);
  static const text = Color(0xFF171717);
  static const muted = Color(0xFF6B7280);
  static const surface = Color(0xFFF8F9FA);
  static const border = Color(0xFFEDEEF0);
}

abstract final class OrderSummaryTheme {
  static final light = HomeTheme.light.copyWith(
    scaffoldBackgroundColor: OrderSummaryColors.surface,
    colorScheme: HomeTheme.light.colorScheme.copyWith(
      primary: OrderSummaryColors.red,
      onPrimary: Colors.white,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: OrderSummaryColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
