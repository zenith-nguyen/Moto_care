import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

abstract final class ChatTheme {
  static const background = HomeColors.background;
  static const surface = HomeColors.surface;
  static const navigationSurface = HomeColors.surface;
  static const red = Color(0xFFFF251E);
  static const orange = HomeColors.primary;
  static const green = Color(0xFF218653);
  static const mutedText = HomeColors.secondary;

  static final light = HomeTheme.light.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.light,
      primary: orange,
      surface: surface,
      onSurface: HomeColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: HomeColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
