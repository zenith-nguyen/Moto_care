import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/theme/home_theme.dart';

abstract final class ActivityTheme {
  static const background = HomeColors.background;
  static const surface = HomeColors.surface;
  static const navigationSurface = HomeColors.surface;
  static const red = HomeColors.red;
  static const orange = HomeColors.primary;
  static const green = Color(0xFF218653);
  static const mutedText = HomeColors.secondary;
  static const primaryAction = Color(0xFF1A1A1A);

  static final light = HomeTheme.light.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: HomeTheme.light.colorScheme.copyWith(
      primary: orange,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: HomeColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: HomeColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
      ),
    ),
  );
}

/// Activity variants retain Home's font family, line height and letter spacing.
abstract final class ActivityTextStyles {
  static final pageTitle = AppTextStyles.pageTitle.copyWith(
    color: Colors.black87,
  );
  static final monthTitle = AppTextStyles.body.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.black54,
  );
  static final metadata = AppTextStyles.caption.copyWith(
    fontWeight: FontWeight.w400,
    color: Colors.black45,
  );
  static final statusBadge = AppTextStyles.caption.copyWith(
    fontWeight: FontWeight.w600,
  );
  static final serviceTitle = AppTextStyles.cardTitle.copyWith(
    color: Colors.black87,
  );
  static final mechanic = AppTextStyles.body.copyWith(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
  static final address = AppTextStyles.caption.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );
  static final payment = AppTextStyles.body.copyWith(
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  static final detailsAction = AppTextStyles.body.copyWith(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
  static final rebookAction = AppTextStyles.body.copyWith(
    fontSize: 13.5,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static final emptyMessage = AppTextStyles.body.copyWith(
    color: Colors.black54,
  );

  static TextStyle filterLabel({required bool selected}) =>
      AppTextStyles.body.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? Colors.white : Colors.black87,
      );
}
