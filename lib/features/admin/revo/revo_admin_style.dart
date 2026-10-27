import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/admin_tokens.dart';

/// Shared chart + card styling for the REVO admin dashboard, mirroring the
/// prototype. Kept dependency-free (no google_fonts, no fl_chart).
abstract final class AdminChartStyle {
  static const blue = Color(0xFF0086C9);
  static const border = Color(0xFFDDE9F5);
  static const muted = Color(0xFF7289AA);
}

const revoCardRadius = BorderRadius.all(Radius.circular(24));

BoxDecoration revoCardDecoration({Color? color, Color? border}) =>
    BoxDecoration(
      color: color ?? AdminTokens.card,
      borderRadius: revoCardRadius,
      border: border == null ? null : Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );

/// Montserrat text style helper (the app bundles Montserrat as a fontFamily).
TextStyle revoFont({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) => TextStyle(
  fontFamily: 'Montserrat',
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

String revoMoney(int value) => NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
  decimalDigits: 0,
).format(value);
