import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'revo_brand.dart';

/// REVO design system for the Provider app, ported from the REVO provider UI
/// reference (Thanh Vy prototype). Colors come from [RevoBrandColors] so the
/// brand stays in one place. This theme is applied only to the provider
/// runtime ([ProviderMotoCareApp]); the customer app keeps its own theme.
abstract final class RevoRadius {
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 22;
  static const double input = 16;
  static const double hero = 26;
  static const double sheet = 28;
  static const double navigation = 32;
  static const double pill = 999;
}

abstract final class RevoShadows {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x0C317CBB), blurRadius: 18, offset: Offset(0, 5)),
  ];
  static const navigation = <BoxShadow>[
    BoxShadow(color: Color(0x14172638), blurRadius: 22, offset: Offset(0, 6)),
  ];
  static const modal = <BoxShadow>[
    BoxShadow(color: Color(0x24172638), blurRadius: 28, offset: Offset(0, -4)),
  ];
}

abstract final class RevoGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      RevoBrandColors.surfaceSoft,
      RevoBrandColors.surface,
      RevoBrandColors.sky,
    ],
  );
  static const balance = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [RevoBrandColors.primary, RevoBrandColors.primaryDeep],
  );
}

abstract final class RevoSpace {
  static const double page = 16;
  static const double section = 16;
  static const double button = 48;
  static const pageInsets = EdgeInsets.all(page);
}

abstract final class RevoTypography {
  static const family = 'Montserrat';
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: RevoBrandColors.textSubtle,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: RevoBrandColors.ink,
  );
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: RevoBrandColors.ink,
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
    color: RevoBrandColors.ink,
  );
  static const heading = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: RevoBrandColors.ink,
  );
  static const amount = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: RevoBrandColors.ink,
  );
}

TextStyle revoText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = RevoBrandColors.ink,
  double? height,
  double? letterSpacing,
}) => RevoTypography.body.copyWith(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height ?? 1.4,
  letterSpacing: letterSpacing,
);

ThemeData buildRevoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: RevoTypography.family,
    scaffoldBackgroundColor: RevoBrandColors.bg,
    colorScheme: const ColorScheme.light(
      primary: RevoBrandColors.primary,
      onPrimary: RevoBrandColors.surface,
      primaryContainer: RevoBrandColors.surfaceSoft,
      onPrimaryContainer: RevoBrandColors.primaryDeep,
      secondary: RevoBrandColors.sky,
      onSecondary: RevoBrandColors.ink,
      surface: RevoBrandColors.surface,
      onSurface: RevoBrandColors.ink,
      error: RevoBrandColors.dangerDark,
      outline: RevoBrandColors.border,
    ),
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(RevoRadius.sm),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(RevoRadius.input),
    borderSide: const BorderSide(color: RevoBrandColors.border),
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          fontFamily: RevoTypography.family,
          bodyColor: RevoBrandColors.ink,
          displayColor: RevoBrandColors.ink,
        )
        .copyWith(
          headlineSmall: RevoTypography.heading,
          titleLarge: RevoTypography.title,
          titleMedium: RevoTypography.label.copyWith(fontSize: 16),
          bodyLarge: RevoTypography.body,
          bodyMedium: RevoTypography.body.copyWith(fontSize: 13),
          bodySmall: RevoTypography.caption,
          labelLarge: RevoTypography.button,
          labelMedium: RevoTypography.label.copyWith(fontSize: 12),
          labelSmall: RevoTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
    iconTheme: const IconThemeData(color: RevoBrandColors.primary, size: 22),
    dividerTheme: const DividerThemeData(
      color: RevoBrandColors.border,
      thickness: .7,
      space: 1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: RevoBrandColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: RevoBrandColors.ink,
      titleTextStyle: RevoTypography.title,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: RevoBrandColors.primary,
        foregroundColor: RevoBrandColors.surface,
        disabledBackgroundColor: RevoBrandColors.border,
        disabledForegroundColor: RevoBrandColors.textSubtle,
        shape: shape,
        textStyle: RevoTypography.button,
        minimumSize: const Size(0, RevoSpace.button),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RevoBrandColors.primary,
        side: const BorderSide(color: RevoBrandColors.border),
        shape: shape,
        textStyle: RevoTypography.button,
        minimumSize: const Size(0, RevoSpace.button),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: RevoBrandColors.primary,
        textStyle: RevoTypography.label,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(RevoBrandColors.surface),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? RevoBrandColors.primary
            : RevoBrandColors.border,
      ),
    ),
    cardTheme: CardThemeData(
      color: RevoBrandColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RevoRadius.md),
        side: const BorderSide(color: RevoBrandColors.border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: RevoBrandColors.surfaceSoft,
      side: BorderSide.none,
      labelStyle: RevoTypography.caption.copyWith(color: RevoBrandColors.ink),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RevoRadius.pill),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: RevoBrandColors.ink,
      contentTextStyle: RevoTypography.body.copyWith(
        color: RevoBrandColors.surface,
      ),
      shape: shape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RevoBrandColors.surface,
      hintStyle: RevoTypography.body.copyWith(color: RevoBrandColors.textMuted),
      labelStyle: RevoTypography.label.copyWith(
        color: RevoBrandColors.textSubtle,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: RevoBrandColors.primary,
          width: 1.4,
        ),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: RevoBrandColors.dangerDark),
      ),
      errorStyle: RevoTypography.caption.copyWith(
        color: RevoBrandColors.dangerDark,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: RevoBrandColors.primary,
      linearTrackColor: RevoBrandColors.surfaceSoft,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: RevoBrandColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: RevoBrandColors.textSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RevoRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: RevoBrandColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RevoRadius.lg),
      ),
      titleTextStyle: RevoTypography.title,
      contentTextStyle: RevoTypography.body,
    ),
  );
}
