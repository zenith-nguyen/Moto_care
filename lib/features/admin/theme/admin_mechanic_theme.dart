import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/admin_tokens.dart';

abstract final class AdminMechanicTheme {
  static const backdrop = Color(0xFF101725);
  static final title = GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AdminTokens.text,
    height: 1.35,
    letterSpacing: -0.5,
  );
  static final heading = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AdminTokens.text,
    height: 1.5,
    letterSpacing: -0.3,
  );
  static final value = GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AdminTokens.text,
    height: 1.6,
    letterSpacing: -0.2,
  );
  static final label = GoogleFonts.montserrat(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AdminTokens.muted,
    height: 1.5,
    letterSpacing: -0.2,
  );
  static final caption = GoogleFonts.montserrat(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AdminTokens.muted,
    height: 1.5,
    letterSpacing: -0.2,
  );
  static const card = BoxDecoration(
    color: AdminTokens.card,
    borderRadius: BorderRadius.all(Radius.circular(18)),
  );
}
