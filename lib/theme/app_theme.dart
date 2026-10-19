import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// REVO shared brand tokens. User source matching the supplied screenshots is
/// not available yet; primary is the explicit brand value supplied by the user.
class AppColors {
  AppColors._();
  static const primary = Color(0xFF317CBB);
  static const primaryDeep = Color(0xFF246598);
  static const sky = Color(0xFF70C5EB);
  static const navy = Color(0xFF234560);
  static const ink = Color(0xFF172638);
  static const darkSurface = Color(0xFF234560);
  static const danger = Color(0xFFFF4545);
  static const dangerDark = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFFF0F0);
  static const bg = Color(0xFFF7F9FD);
  static const light = Color(0xFFF2F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFEAF4FC);
  static const border = Color(0xFFE4EBF3);
  static const textSub = Color(0xFF718096);
  static const textMuted = Color(0xFF8090A4);
  static const success = Color(0xFF12B76A);
  static const successDark = Color(0xFF087443);
  static const successSoft = Color(0xFFE8F8F0);
  static const warning = Color(0xFFFF9500);
  static const warningDark = Color(0xFF9A5500);
  static const warningSoft = Color(0xFFFFF5E5);
  static const mapBase = Color(0xFFF0F4F6);
  static const mapPark = Color(0xFFE1F0E9);
  static const mapWater = Color(0xFFBDE5F4);
}

class AppRadius {
  AppRadius._();
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 22;
  static const double input = 16;
  static const double hero = 26;
  static const double sheet = 28;
  static const double navigation = 32;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x0C317CBB), blurRadius: 18, offset: Offset(0, 5)),
  ];
  static const navigation = <BoxShadow>[
    BoxShadow(color: Color(0x12172638), blurRadius: 24, offset: Offset(0, 5)),
  ];
  static const modal = <BoxShadow>[
    BoxShadow(color: Color(0x24172638), blurRadius: 28, offset: Offset(0, -4)),
  ];
}

class AppGradients {
  AppGradients._();
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceSoft, AppColors.surface, AppColors.sky],
  );
  static const balance = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDeep],
  );
}

class AppSpace {
  AppSpace._();
  static const double page = 16;
  static const double section = 16;
  static const double button = 48;
  static const pageInsets = EdgeInsets.all(page);
  static const footerInsets = EdgeInsets.fromLTRB(page, 8, page, 12);
}

/// Keep the existing offline Montserrat bundle while the exact User source is
/// being located. All app text and Material fallbacks use the same family.
class AppTypography {
  AppTypography._();
  static const family = 'Montserrat';
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSub,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.ink,
  );
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.ink,
  );
  static const button = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.ink,
  );
  static const heading = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.ink,
  );
  static const amount = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.ink,
  );
}

TextStyle appText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height,
  double? letterSpacing,
}) =>
    AppTypography.body.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? 1.4,
      letterSpacing: letterSpacing,
    );

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.family,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.surfaceSoft,
      onPrimaryContainer: AppColors.primaryDeep,
      secondary: AppColors.sky,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.dangerDark,
      outline: AppColors.border,
    ),
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.sm),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.input),
    borderSide: const BorderSide(color: AppColors.border),
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          fontFamily: AppTypography.family,
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        )
        .copyWith(
          headlineSmall: AppTypography.heading,
          titleLarge: AppTypography.title,
          titleMedium: AppTypography.label.copyWith(fontSize: 16),
          bodyLarge: AppTypography.body,
          bodyMedium: AppTypography.body.copyWith(fontSize: 13),
          bodySmall: AppTypography.caption,
          labelLarge: AppTypography.button,
          labelMedium: AppTypography.label.copyWith(fontSize: 12),
          labelSmall: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
    iconTheme: const IconThemeData(color: AppColors.primary, size: 22),
    listTileTheme: const ListTileThemeData(
      dense: true,
      minVerticalPadding: 8,
      minLeadingWidth: 22,
      horizontalTitleGap: 12,
      contentPadding: EdgeInsets.zero,
      iconColor: AppColors.primary,
      titleTextStyle: AppTypography.body,
      subtitleTextStyle: AppTypography.caption,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: .7,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.ink,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textSub,
        shape: shape,
        textStyle: AppTypography.button,
        minimumSize: const Size(0, AppSpace.button),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: shape,
        textStyle: AppTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.label,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(AppColors.surface),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.border,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: AppTypography.body.copyWith(color: AppColors.surface),
      shape: shape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
      labelStyle: AppTypography.label.copyWith(color: AppColors.textSub),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.dangerDark),
      ),
      errorStyle: AppTypography.caption.copyWith(color: AppColors.dangerDark),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceSoft,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.textSub,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      titleTextStyle: AppTypography.title,
      contentTextStyle: AppTypography.body,
    ),
  );
}
