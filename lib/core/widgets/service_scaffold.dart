import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/models/home_destination.dart';
import '../../features/home/theme/home_theme.dart';
import '../../features/home/widgets/brand_backdrop.dart';
import '../../features/home/widgets/home_bottom_navigation.dart';
import '../router/main_navigation.dart';

abstract final class ServiceColors {
  static const orange = HomeColors.primary;
  static const gold = HomeColors.primary;
  static const goldBackground = HomeColors.selected;
  static const surface = HomeColors.surface;
  static const muted = HomeColors.secondary;
  static const navy = HomeColors.selected;
  static const border = HomeColors.border;
  static const text = HomeColors.text;
}

class ServiceScaffold extends StatelessWidget {
  const ServiceScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomBar,
    this.actions = const [],
    this.background = HomeColors.background,
    this.selectedDestination = HomeDestination.services,
  });

  final String title;
  final Widget body;
  final Widget? bottomBar;
  final List<Widget> actions;
  final Color background;
  final HomeDestination selectedDestination;

  @override
  Widget build(BuildContext context) {
    final theme = HomeTheme.light;
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: ServiceColors.orange,
          surface: ServiceColors.surface,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: ServiceColors.orange,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: HomeColors.text,
            side: const BorderSide(color: HomeColors.border),
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: ServiceColors.surface,
          hintStyle: const TextStyle(color: ServiceColors.muted, fontSize: 15),
          labelStyle: const TextStyle(color: ServiceColors.muted, fontSize: 15),
        ),
        cardTheme: CardThemeData(
          color: ServiceColors.surface,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: ServiceColors.surface,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
        ),
      ),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          actions: actions,
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          foregroundColor: HomeColors.text,
          flexibleSpace: const BrandBackdrop(child: SizedBox.expand()),
          toolbarHeight: MediaQuery.textScalerOf(context).scale(80),
          leading: IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/trang-chu');
              }
            },
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: body,
            ),
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bottomBar != null)
              SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 668),
                      child: bottomBar,
                    ),
                  ),
                ),
              ),
            HomeBottomNavigation(
              selectedDestination: selectedDestination,
              onSelected: (destination) =>
                  navigateMainTab(context, destination),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceSectionTitle extends StatelessWidget {
  const ServiceSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    ),
  );
}

class ServiceSearchBar extends StatelessWidget {
  const ServiceSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.controller,
  });
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: hint,
      controller: controller,
      leading: const Icon(Icons.search_rounded),
      onChanged: onChanged,
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: const WidgetStatePropertyAll(ServiceColors.surface),
      textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 15)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

void showServiceMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Make search usable with either Vietnamese accents or plain ASCII input.
String normalizeServiceSearch(String value) {
  var result = value.trim().toLowerCase();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    for (final rune in entry.value.runes) {
      result = result.replaceAll(String.fromCharCode(rune), entry.key);
    }
  }
  return result;
}
