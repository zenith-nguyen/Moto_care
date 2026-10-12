import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bảng màu theo Design System MotoCare (giao diện Thợ).
class AppColors {
  AppColors._();

  /// Primary: nút CTA chính, header, nav active.
  static const Color ink = Color(0xFF0E0E10);

  /// Alert/Urgent: badge khẩn cấp, lý do từ chối, bị từ chối, số tiền trừ, đăng xuất.
  static const Color danger = Color(0xFFE63946);
  static const Color dangerDark = Color(0xFFC62833); // chữ đỏ trên nền đỏ nhạt
  static const Color dangerSoft = Color(0xFFFDE8EA);

  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceSoft = Color(0xFFF7F7F7);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textSub = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  /// Success: đã duyệt, đã xác minh, số tiền cộng.
  static const Color success = Color(0xFF1F9254);
  static const Color successSoft = Color(0xFFE6F4EC);

  /// Warning/Pending: chờ xác minh, đang chờ duyệt.
  static const Color warning = Color(0xFFF2A93B);
  static const Color warningDark = Color(0xFF8A5A00); // chữ vàng trên nền vàng nhạt
  static const Color warningSoft = Color(0xFFFDF0DA);

  /// Map placeholder.
  static const Color mapBase = Color(0xFFEDEFF1);
  static const Color mapPark = Color(0xFFDCE8DA);
  static const Color mapWater = Color(0xFFD6E6F2);
}

/// Bo góc nhất quán 16–28px.
class AppRadius {
  AppRadius._();
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double input = 28;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 4)),
  ];
}

/// TextStyle dùng font Montserrat.
TextStyle appText(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = AppColors.ink,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.montserrat(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.ink).copyWith(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.ink,
      error: AppColors.danger,
      surface: AppColors.bg,
      onSurface: AppColors.ink,
    ),
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.input),
    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.montserratTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    dividerColor: AppColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: appText(13.5, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: appText(15, color: const Color(0xFFB8BDC6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      disabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
      errorStyle: appText(12, color: AppColors.danger),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.ink,
      linearTrackColor: AppColors.border,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  );
}
