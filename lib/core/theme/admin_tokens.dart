import 'package:flutter/material.dart';

/// Shared semantic colors for administrative surfaces. Existing app themes
/// remain independent so adding the admin role does not recolor other roles.
abstract final class AdminTokens {
  static const primaryBlue = Color(0xFF1976D2);
  static const primaryRed = Color(0xFFE53935);
  static const background = Color(0xFFFFFFFF);
  static const accountBackground = Color(0xFF9FD7F9);
  static const accountBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.white,
      Color(0xFFF7FBFE),
      Color(0xFFE2F2FC),
      accountBackground,
    ],
    stops: [0, 0.3, 0.65, 1],
  );
  static const card = Color(0xFFF8F9FA);
  static const activePill = Color(0xFFE8F0FE);
  static const inactivePill = Color(0xFFF0F2F5);
  static const inactivePillText = Color(0xFF666666);
  static const surface = Colors.white;
  static const text = Color(0xFF1A1A1A);
  static const muted = Color(0xFF757575);
  static const border = Color(0xFFEEEEEE);
  static const success = Color(0xFF218552);
  static const warning = Color(0xFF986400);
  static const neutral = Color(0xFF697586);
}
