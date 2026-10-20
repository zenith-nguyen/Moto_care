import 'package:flutter/material.dart';

/// Shared REVO brand tokens for Customer and Provider surfaces.
///
/// Provider PR #51 introduced these colors. Keeping the canonical values in
/// the shared foundation prevents each role app from drifting visually while
/// still reserving red for destructive and emergency meaning.
abstract final class RevoBrandColors {
  static const primary = Color(0xFF317CBB);
  static const primaryDeep = Color(0xFF246598);
  static const sky = Color(0xFF70C5EB);
  static const navy = Color(0xFF234560);
  static const ink = Color(0xFF172638);
  static const textSubtle = Color(0xFF718096);
  static const surfaceSoft = Color(0xFFEAF4FC);
  static const border = Color(0xFFE4EBF3);
  static const danger = Color(0xFFFF4545);
  static const dangerDark = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFFF0F0);
  static const success = Color(0xFF12B76A);
  static const warning = Color(0xFFFF9500);
}
