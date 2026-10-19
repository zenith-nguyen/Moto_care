import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Montserrat roles shared by Admin screens, cards and Material controls.
abstract final class AdminTypography {
  static const titleSpacing = -0.5;
  static const actionSpacing = -0.3;
  static const bodySpacing = -0.2;

  static final pageTitle = GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: titleSpacing,
    height: 1.3,
  );
  static final cardTitle = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: actionSpacing,
    height: 1.3,
  );
  static final body = GoogleFonts.montserrat(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: bodySpacing,
    color: const Color(0xA3000000),
    height: 1.4,
  );
  static final caption = GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: bodySpacing,
    color: Colors.black54,
    height: 1.4,
  );
  static final label = GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: bodySpacing,
    height: 1.4,
  );
  static final status = GoogleFonts.montserrat(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    letterSpacing: bodySpacing,
    height: 1.3,
  );
  static final button = GoogleFonts.montserrat(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: actionSpacing,
    height: 1.3,
  );

  /// Retain existing sizes and line heights while assigning semantic weights.
  static TextTheme textTheme(TextTheme base) {
    TextStyle role(TextStyle? style, FontWeight weight, double spacing) =>
        GoogleFonts.montserrat(
          textStyle: style,
          fontWeight: weight,
          letterSpacing: spacing,
        );

    return TextTheme(
      displayLarge: role(base.displayLarge, FontWeight.w700, titleSpacing),
      displayMedium: role(base.displayMedium, FontWeight.w700, titleSpacing),
      displaySmall: role(base.displaySmall, FontWeight.w700, titleSpacing),
      headlineLarge: role(base.headlineLarge, FontWeight.w700, titleSpacing),
      headlineMedium: role(base.headlineMedium, FontWeight.w700, titleSpacing),
      headlineSmall: role(base.headlineSmall, FontWeight.w700, titleSpacing),
      titleLarge: role(base.titleLarge, FontWeight.w700, actionSpacing),
      titleMedium: role(base.titleMedium, FontWeight.w600, actionSpacing),
      titleSmall: role(base.titleSmall, FontWeight.w600, actionSpacing),
      bodyLarge: role(base.bodyLarge, FontWeight.w400, bodySpacing),
      bodyMedium: role(base.bodyMedium, FontWeight.w400, bodySpacing),
      bodySmall: role(base.bodySmall, FontWeight.w400, bodySpacing),
      labelLarge: role(base.labelLarge, FontWeight.w500, bodySpacing),
      labelMedium: role(base.labelMedium, FontWeight.w500, bodySpacing),
      labelSmall: role(base.labelSmall, FontWeight.w500, bodySpacing),
    );
  }
}
