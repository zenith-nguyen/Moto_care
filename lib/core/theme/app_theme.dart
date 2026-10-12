import 'package:flutter/material.dart';

import '../../features/home/theme/home_theme.dart';

abstract final class AppTextStyles {
  static const pageTitle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  static const cardTitle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  static const body = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 13,
    color: Color(0xA3000000),
    height: 1.4,
  );
  static const caption = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 12,
    color: Colors.black54,
    height: 1.4,
  );
  static const status = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}

abstract final class AppCardLayout {
  static const radius = 16.0;
  static const padding = 16.0;
  static const photoPadding = 10.0;
  static const gap = 12.0;
  static const smallGap = 6.0;
}

abstract final class AppTheme {
  static const primary = HomeColors.red;
  static const link = HomeColors.red;
  static const mutedText = HomeColors.secondary;

  static final light = HomeTheme.red.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HomeColors.surface,
      hintStyle: const TextStyle(color: HomeColors.secondary, fontSize: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary),
      ),
      errorMaxLines: 2,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: link,
        textStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 16),
      ),
    ),
  );
}
