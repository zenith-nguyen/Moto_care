import 'package:flutter/material.dart';

import '../../home/theme/home_theme.dart';

abstract final class ChatTheme {
  static const background = HomeColors.background;
  static const surface = HomeColors.surface;
  static const navigationSurface = HomeColors.surface;
  static const red = HomeColors.red;
  static const orange = HomeColors.primary;
  static const green = Color(0xFF218653);
  static const mutedText = HomeColors.secondary;
  static const messageRed = HomeColors.primary;
  static const inputBackground = Color(0xFFF5F5F5);
  static const incomingBackground = Color(0xFFF2F2F4);
  static const messageText = Color(0xFF3A3A3C);
  static const timestamp = Color(0xFF8E8E93);
  static const border = HomeColors.border;

  static final light = HomeTheme.light.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: HomeTheme.light.colorScheme.copyWith(
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
