import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/features/auth/screens/forgot_password_screen.dart';
import 'package:moto_care/features/auth/screens/login_screen.dart';

Future<GoRouter> openRecovery(WidgetTester tester) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  router.go('/forgot-password');
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('Recovery shows the MotoCare logo and an email-only form', (
    tester,
  ) async {
    await openRecovery(tester);

    expect(find.text('Quên mật khẩu'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/Logo_motocare.png')),
      findsOneWidget,
    );
    expect(
      find.text('Vui lòng nhập email mà bạn đã đăng ký tài khoản.'),
      findsOneWidget,
    );
    expect(find.text('Mã xác thực sẽ được gửi qua email.'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsNothing);
    expect(find.text('+84'), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.keyboardType, TextInputType.emailAddress);
    expect(input.autofillHints, contains(AutofillHints.email));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Email validation blocks empty and malformed submissions', (
    tester,
  ) async {
    await openRecovery(tester);
    final field = find.byType(TextFormField);
    final submit = find.byType(FilledButton);

    await tester.showKeyboard(field);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập email'), findsOneWidget);

    for (final email in [
      '0912345678',
      'name@',
      'name@domain',
      'a b@mail.com',
    ]) {
      await tester.enterText(field, email);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(find.byType(SnackBar), findsNothing);
    }

    await tester.enterText(field, '  rider+care@example.com  ');
    await tester.pumpAndSettle();
    expect(find.text('Email không hợp lệ'), findsNothing);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.enterText(field, '');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Keyboard submission reports recovery availability', (
    tester,
  ) async {
    await openRecovery(tester);
    await tester.enterText(find.byType(TextFormField), 'rider@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      find.text('Tính năng gửi mã xác thực qua email sẽ sớm được hỗ trợ.'),
      findsOneWidget,
    );
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recovery supports large text and scrolling above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openRecovery(tester);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextFormField), 'rider@example.com');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(
      find.text('Tính năng gửi mã xác thực qua email sẽ sớm được hỗ trợ.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Opening recovery directly can return to login', (tester) async {
    final router = await openRecovery(tester);
    expect(router.canPop(), isFalse);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
