import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:moto_care/features/auth/screens/forgot_password_screen.dart';
import 'package:moto_care/features/auth/screens/login_screen.dart';
import 'package:moto_care/features/auth/screens/register_screen.dart';
import 'package:moto_care/features/home/screens/trang_chu.dart';
import 'package:moto_care/main.dart';

Future<void> openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('App opens login immediately after the native splash', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    final loginLogo = find.image(
      const AssetImage('assets/images/logo-motocare.png'),
    );
    expect(loginLogo, findsOneWidget);
    expect(
      tester.getBottomLeft(loginLogo).dy,
      lessThan(tester.getTopLeft(find.byType(TextFormField).first).dy),
    );
    expect(find.text('Email hoặc số điện thoại'), findsOneWidget);
    expect(find.text('Nhập email hoặc số điện thoại của bạn'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('Đăng ký'), findsOneWidget);
    expect(find.text('[DEV] Vào nhanh Trang chủ'), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byType(LoginScreen))).canPop(),
      false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Password visibility toggles without clearing the password', (
    tester,
  ) async {
    await openLogin(tester);
    final passwordField = find.byType(TextFormField).last;
    final passwordInput = find.byType(EditableText).last;
    await tester.enterText(passwordField, 'my-password');
    expect(tester.widget<EditableText>(passwordInput).obscureText, isTrue);

    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(tester.widget<EditableText>(passwordInput).obscureText, isFalse);
    expect(
      tester.widget<EditableText>(passwordInput).controller.text,
      'my-password',
    );

    await tester.tap(find.byTooltip('Ẩn mật khẩu'));
    await tester.pump();
    expect(tester.widget<EditableText>(passwordInput).obscureText, isTrue);
  });

  testWidgets(
    'Login accepts email and phone without filtering their characters',
    (tester) async {
      await openLogin(tester);
      final identifier = find.byKey(const ValueKey('login-identifier'));
      final input = find.descendant(
        of: identifier,
        matching: find.byType(EditableText),
      );
      await tester.enterText(find.byType(TextFormField).last, 'MotoCare1!');
      for (final value in [
        'rider+test@example.com',
        '0912345678',
        '+84912345678',
      ]) {
        await tester.enterText(identifier, value);
        await tester.pump();
        expect(tester.widget<EditableText>(input).controller.text, value);
        expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
      }
      await tester.enterText(identifier, 'rider@');
      await tester.pump();
      expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
      await tester.pump();
      expect(
        find.text('Email hoặc số điện thoại không hợp lệ'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Temporary login bypass opens home without credentials', (
    tester,
  ) async {
    await openLogin(tester);
    await tester.ensureVisible(find.text('Đăng nhập'));
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(TrangChu), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(GoRouter.of(tester.element(find.byType(TrangChu))).canPop(), false);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Temporary login bypass opens home with malformed credentials', (
    tester,
  ) async {
    await openLogin(tester);
    await tester.enterText(find.byType(TextFormField).first, '123');
    await tester.enterText(find.byType(TextFormField).last, 'my-password');
    await tester.ensureVisible(find.text('Đăng nhập'));
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(TrangChu), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DEV shortcut below registration opens home immediately', (
    tester,
  ) async {
    await openLogin(tester);
    final shortcut = find.widgetWithText(
      TextButton,
      '[DEV] Vào nhanh Trang chủ',
    );
    await tester.ensureVisible(shortcut);
    expect(
      tester.getTopLeft(shortcut).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('Đăng ký')).dy),
    );
    await tester.tap(shortcut);
    await tester.pumpAndSettle();
    expect(find.byType(TrangChu), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(GoRouter.of(tester.element(find.byType(TrangChu))).canPop(), false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Keyboard submit also uses the temporary login bypass', (
    tester,
  ) async {
    await openLogin(tester);
    await tester.enterText(find.byType(TextFormField).first, '0912345678');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .focusNode
          .hasFocus,
      isTrue,
    );
    await tester.enterText(find.byType(TextFormField).last, 'my-password');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(TrangChu), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recovery and registration return to the existing login form', (
    tester,
  ) async {
    await openLogin(tester);
    await tester.enterText(find.byType(TextFormField).first, '0912345678');
    await tester.enterText(find.byType(TextFormField).last, 'my-password');
    await tester.ensureVisible(find.text('Quên mật khẩu?'));
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('0912345678'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .controller
          .text,
      'my-password',
    );
    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Đăng ký tài khoản MotoCare'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Small screens support large text and scrolling above keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openLogin(tester);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextFormField).last, 'my-password');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('[DEV] Vào nhanh Trang chủ'));
    await tester.tap(find.text('[DEV] Vào nhanh Trang chủ'));
    await tester.pumpAndSettle();
    expect(find.byType(TrangChu), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
