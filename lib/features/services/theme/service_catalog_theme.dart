import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/revo_brand.dart';

abstract final class ServiceCatalogTheme {
  static const blue = RevoBrandColors.primary;
  static const background = Color(0xFFF7F8FA);
  static const muted = Color(0xFF68768A);
  static const border = Color(0xFFE2E7EF);
  static const paleBlue = Color(0xFFE8F3FE);
  static final light = AppTheme.light.copyWith(
    colorScheme: AppTheme.light.colorScheme.copyWith(
      primary: blue,
      secondary: blue,
    ),
    scaffoldBackgroundColor: background,
  );
}
