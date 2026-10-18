import 'package:flutter/material.dart';

import '../../../core/theme/admin_tokens.dart';

abstract final class AdminMechanicTheme {
  static const backdrop = Color(0xFF101725);
  static const title = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AdminTokens.text,
    height: 1.35,
  );
  static const heading = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AdminTokens.text,
    height: 1.5,
  );
  static const value = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AdminTokens.text,
    height: 1.6,
  );
  static const label = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AdminTokens.muted,
    height: 1.5,
  );
  static const card = BoxDecoration(
    color: AdminTokens.card,
    borderRadius: BorderRadius.all(Radius.circular(18)),
  );
}
