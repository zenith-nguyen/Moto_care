import 'package:flutter/material.dart';

import '../../../core/theme/admin_tokens.dart';

abstract final class AdminOrderTheme {
  static const radius = BorderRadius.all(Radius.circular(20));
  static const label = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xFF8E8E93),
    height: 1.5,
  );
  static const value = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AdminTokens.text,
    height: 1.5,
  );
  static const title = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AdminTokens.text,
    height: 1.4,
  );
}
