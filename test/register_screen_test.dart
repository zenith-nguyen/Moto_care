import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/auth/screens/register_screen.dart';
import 'package:moto_care/main.dart';

Future<void> openRegister(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Đăng ký'));
  await tester.tap(find.text('Đăng ký'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Registration shows MotoCare branding and the requested hotline',
    (tester) async {
      await openRegister(tester);

      expect(find.text('Đăng ký tài khoản MotoCare'), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/Logo_motocare.png')),
        findsOneWidget,
      );
      expect(find.text('+84'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Nhập email của bạn'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Email')).dy,
        lessThan(tester.getTopLeft(find.text('Số điện thoại')).dy),
      );
      expect(
        find.textContaining('hotline 1130', findRichText: true),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.close_rounded), findsNWidgets(4));
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Password requirements update as the password changes', (
    tester,
  ) async {
    await openRegister(tester);
    final passwordField = find.byType(TextFormField).last;
    for (final (password, satisfiedCount) in [
      ('abcdefgh', 1),
      ('Abcdefgh', 2),
      ('Abcdefg1', 3),
      ('Abcdef1!', 4),
      ('short', 0),
    ]) {
      await tester.enterText(passwordField, password);
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(satisfiedCount));
      expect(
        find.byIcon(Icons.close_rounded),
        findsNWidgets(4 - satisfiedCount),
      );
    }
  });

  testWidgets('Registration password visibility preserves the entered value', (
    tester,
  ) async {
    await openRegister(tester);
    final passwordField = find.byType(TextFormField).last;
    final passwordInput = find.byType(EditableText).last;
    await tester.enterText(passwordField, 'MotoCare1!');
    expect(tester.widget<EditableText>(passwordInput).obscureText, isTrue);
    await tester.ensureVisible(find.byTooltip('Hiện mật khẩu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(tester.widget<EditableText>(passwordInput).obscureText, isFalse);
    expect(
      tester.widget<EditableText>(passwordInput).controller.text,
      'MotoCare1!',
    );
    await tester.ensureVisible(find.byTooltip('Ẩn mật khẩu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ẩn mật khẩu'));
    await tester.pump();
    expect(tester.widget<EditableText>(passwordInput).obscureText, isTrue);
  });

  testWidgets('Submission requires valid credentials and consent', (
    tester,
  ) async {
    await openRegister(tester);
    final phoneField = find.byKey(const ValueKey('register-phone'));
    final passwordField = find.byType(TextFormField).last;
    final submit = find.byType(FilledButton);
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'rider@example.com',
    );
    await tester.enterText(phoneField, '123');
    await tester.enterText(passwordField, 'MotoCare1!');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(find.byType(SnackBar), findsNothing);

    await tester.enterText(phoneField, '0912345678');
    await tester.enterText(passwordField, 'MotoCare1!');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.text('Vui lòng đồng ý với Điều khoản và Chính sách quyền riêng tư.'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Đăng ký tài khoản sẽ sớm được hỗ trợ.'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets(
    'Registration requires a valid email along with phone, password and consent',
    (tester) async {
      await openRegister(tester);
      final email = find.byKey(const ValueKey('register-email'));
      final submit = find.byType(FilledButton);
      await tester.enterText(
        find.byKey(const ValueKey('register-phone')),
        '0912345678',
      );
      await tester.enterText(find.byType(TextFormField).last, 'MotoCare1!');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      await tester.enterText(email, 'rider@');
      await tester.pump();
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      await tester.enterText(email, ' rider+test@example.com ');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const ValueKey('register-phone')),
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(find.text('Email không hợp lệ'), findsNothing);
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      await tester.enterText(email, '');
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    },
  );

  testWidgets('Registration remains usable with large text and a keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openRegister(tester);
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'rider@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-phone')),
      '912345678',
    );
    await tester.enterText(find.byType(TextFormField).last, 'MotoCare1!');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Đăng ký tài khoản sẽ sớm được hỗ trợ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Opening registration directly can return to login', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Login route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(router.canPop(), isFalse);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Login route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
