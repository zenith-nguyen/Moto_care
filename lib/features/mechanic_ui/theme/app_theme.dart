import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bang mau theo Design System cua MotoCare.
class AppColors {
  AppColors._();

  // ĐỔI MÀU THEO ĐỀ 2 (CTA cam, online xanh): sửa 4 dòng dưới đây rồi hot restart:
  //   primary     -> Color(0xFFFF6B35)
  //   primarySoft -> Color(0xFFFFEEE6)
  //   primaryDark -> Color(0xFFB3430F)
  //   online      -> success
  static const Color primary = Color(0xFFE63946); // CTA, badge khan cap
  static const Color primaryDark = Color(
    0xFFC62833,
  ); // chu do tren nen do nhat (du tuong phan)
  static const Color primarySoft = Color(0xFFFDECEE);

  static const Color ink = Color(0xFF1A1A1A); // header, text chinh, nav active
  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color border = Color(0xFFE5E5E5);
  static const Color textSub = Color(0xFF6B7280);

  static const Color success = Color(0xFF1F9254);
  static const Color successDark = Color(
    0xFF146B3A,
  ); // chu xanh tren nen xanh nhat
  static const Color successSoft = Color(0xFFE3F4EB);

  /// Màu trạng thái ONLINE (Switch nhận đơn, chấm trạng thái).
  static const Color online = primary;

  static const Color warning = Color(0xFFF2A93B);
  static const Color warningSoft = Color(0xFFFEF3E0);

  static const Color disabled = Color(0xFF9CA3AF); // reject / offline

  static const Color wrappedBg = Color(0xFF13203A); // man Tong ket tuan
}

class AppRadius {
  AppRadius._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
}

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4)),
  ];
}

/// Tien ich dat do trong suot (tuong thich moi phien ban Flutter).
extension ColorOpacityX on Color {
  Color op(double opacity) =>
      withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}

/// TextStyle dung font Be Vietnam Pro.
TextStyle appText(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.ink,
  double? height,
  double? letterSpacing,
  TextDecoration? decoration,
}) {
  return GoogleFonts.beVietnamPro(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.ink,
          onSecondary: Colors.white,
          error: AppColors.primary,
          surface: AppColors.bg,
          onSurface: AppColors.ink,
        ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.beVietnamProTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    dividerColor: AppColors.border,
    splashFactory: InkRipple.splashFactory,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: appText(13.5, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: appText(14, color: AppColors.textSub),
      hintStyle: appText(14, color: AppColors.disabled),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.border,
    ),
  );
}
