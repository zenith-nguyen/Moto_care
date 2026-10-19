import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:revo/core/router/app_router.dart';
import 'package:revo/core/theme/app_theme.dart';
import 'package:revo/features/auth/screens/login_screen.dart';
import 'package:revo/features/auth/screens/register_screen.dart';
import 'package:revo/features/auth/screens/welcome_screen.dart';
import 'package:revo/features/auth/theme/auth_theme.dart';
import 'package:revo/features/activity/theme/activity_theme.dart';
import 'package:revo/features/chat/theme/chat_theme.dart';
import 'package:revo/features/home/theme/home_theme.dart';
import 'package:revo/features/home/theme/revo_home_theme.dart';
import 'package:revo/features/profile/theme/profile_theme.dart';

Future<GoRouter> _openWelcome(WidgetTester tester) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void _expectAuthPalette(WidgetTester tester, Finder content) {
  final theme = Theme.of(tester.element(content));
  expect(theme.scaffoldBackgroundColor, Colors.white);
  expect(theme.colorScheme.primary, Colors.black);
  expect(theme.colorScheme.error, Colors.black);
  expect(theme.textTheme.bodyMedium?.fontFamily, 'Montserrat');
  expect(
    theme.filledButtonTheme.style?.backgroundColor?.resolve({}),
    Colors.black,
  );
  expect(
    theme.textButtonTheme.style?.foregroundColor?.resolve({}),
    Colors.black,
  );
}

void main() {
  for (final size in [const Size(390, 844), const Size(600, 840)]) {
    testWidgets('Welcome shows only the image and Continue button at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await _openWelcome(tester);

      final image = find.image(const AssetImage(WelcomeScreen.imageAsset));
      final bounds = tester.getRect(image);
      expect(bounds.topLeft, Offset.zero);
      expect(bounds.right, size.width);
      expect(bounds.bottom, size.height);
      expect(find.text('Tiếp'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);

      final continueButton = find.widgetWithText(FilledButton, 'Tiếp');
      expect(tester.getCenter(continueButton).dx, closeTo(size.width / 2, 1));
      expect(
        tester.getRect(continueButton).bottom,
        lessThanOrEqualTo(size.height - 34),
      );
      expect(tester.getRect(continueButton).top, greaterThan(size.height / 2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Continue opens login and registration remains accessible', (
    tester,
  ) async {
    final router = await _openWelcome(tester);
    expect(router.state.uri.path, '/welcome');
    _expectAuthPalette(tester, find.text('Tiếp'));

    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    _expectAuthPalette(tester, find.text('Email hoặc số điện thoại'));
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);

    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    _expectAuthPalette(tester, find.text('Email'));
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/welcome');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recovery uses the white, black and gray auth palette', (
    tester,
  ) async {
    final router = await _openWelcome(tester);
    router.go('/forgot-password');
    await tester.pumpAndSettle();
    _expectAuthPalette(tester, find.text('Email'));
    await tester.enterText(find.byType(TextFormField), 'rider@example.com');
    await tester.pump();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
    expect(button.style?.backgroundColor?.resolve({}), Colors.black);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Continue stays accessible on small welcome screens with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _openWelcome(tester);
      final button = find.widgetWithText(FilledButton, 'Tiếp');
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(568 - 34));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('All application and feature themes use Montserrat', () {
    for (final theme in [
      AppTheme.light,
      HomeTheme.light,
      HomeTheme.red,
      RevoHomeTheme.light,
      AuthTheme.light,
      ActivityTheme.light,
      ChatTheme.light,
      ProfileTheme.light,
    ]) {
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Montserrat');
      expect(theme.textTheme.titleLarge?.fontFamily, 'Montserrat');
      expect(
        theme.appBarTheme.titleTextStyle?.fontFamily ??
            theme.textTheme.titleLarge?.fontFamily,
        'Montserrat',
      );
    }
  });
}
