import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/admin_tokens.dart';

abstract final class AdminOrderTheme {
  static const radius = BorderRadius.all(Radius.circular(20));
  static final label = GoogleFonts.montserrat(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xFF8E8E93),
    height: 1.5,
    letterSpacing: -0.2,
  );
  static final value = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AdminTokens.text,
    height: 1.5,
    letterSpacing: -0.2,
  );
  static final title = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AdminTokens.text,
    height: 1.4,
    letterSpacing: -0.3,
  );
}
