import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:moto_care/core/router/app_router.dart';
import 'package:moto_care/core/theme/app_theme.dart';
import 'package:moto_care/core/network/api_failure.dart';
import 'package:moto_care/core/widgets/revo_logo.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/screens/register_screen.dart';
import 'package:moto_care/app/app_dependencies.dart';

import 'support/memory_token_store.dart';
import 'support/recording_auth_repository.dart';

Future<void> openRegister(
  WidgetTester tester, {
  RecordingAuthRepository? repository,
  Set<AppRole>? allowedRoles,
}) async {
  final router = createAppRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          repository ?? RecordingAuthRepository(),
        ),
        tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
        if (allowedRoles != null)
          runtimeAllowedRolesProvider.overrideWithValue(allowedRoles),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tiếp'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Đăng ký'));
  await tester.tap(find.text('Đăng ký'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Registration shows Revo branding and the requested hotline', (
    tester,
  ) async {
    await openRegister(tester);

    expect(find.text('Đăng ký tài khoản Revo'), findsOneWidget);
    expect(find.byType(RevoLogo), findsOneWidget);
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
  });

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
    final repository = RecordingAuthRepository();
    await openRegister(tester, repository: repository);
    final phoneField = find.byKey(const ValueKey('register-phone'));
    final passwordField = find.byType(TextFormField).last;
    final submit = find.byType(FilledButton);
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'rider@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-name')),
      'Customer Test',
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
    expect(repository.registeredName, 'Customer Test');
    expect(repository.registeredEmail, 'rider@example.com');
    expect(repository.registeredPhone, '0912345678');
    expect(repository.registeredRole, AppRole.customer);
  });

  testWidgets('Provider flavor registers a provider account', (tester) async {
    final repository = RecordingAuthRepository();
    await openRegister(
      tester,
      repository: repository,
      allowedRoles: const {AppRole.provider},
    );
    expect(find.text('Đăng ký tài khoản Thợ'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'provider@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-name')),
      'Provider Test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-phone')),
      '0912345678',
    );
    await tester.enterText(find.byType(TextFormField).last, 'MotoCare1!');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    final submit = find.byType(FilledButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repository.registeredRole, AppRole.provider);
  });

  testWidgets('Legal links open full documents and return to registration', (
    tester,
  ) async {
    await openRegister(tester);
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'provider@example.com',
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('register-terms-link')),
    );
    await tester.tap(find.byKey(const ValueKey('register-terms-link')));
    await tester.pumpAndSettle();
    expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    expect(find.text('1. Tài khoản và xác minh'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('register-email')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'provider@example.com',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('register-privacy-link')),
    );
    await tester.tap(find.byKey(const ValueKey('register-privacy-link')));
    await tester.pumpAndSettle();
    expect(find.text('Chính sách quyền riêng tư'), findsOneWidget);
    expect(find.text('1. Dữ liệu được thu thập'), findsOneWidget);
  });

  testWidgets('Registration shows a useful API error instead of debug text', (
    tester,
  ) async {
    final repository = RecordingAuthRepository()
      ..registerFailure = const ApiFailure(
        kind: ApiFailureKind.conflict,
        message: 'Email hoặc số điện thoại đã được đăng ký. Hãy đăng nhập hoặc dùng thông tin khác.',
        statusCode: 409,
      );
    await openRegister(
      tester,
      repository: repository,
      allowedRoles: const {AppRole.provider},
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'provider@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-name')),
      'Provider Test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-phone')),
      '0912345678',
    );
    await tester.enterText(find.byType(TextFormField).last, 'MotoCare1!');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Email hoặc số điện thoại đã được đăng ký. Hãy đăng nhập hoặc dùng thông tin khác.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('ApiFailure('), findsNothing);
  });

  testWidgets(
    'Registration requires a valid email along with phone, password and consent',
    (tester) async {
      await openRegister(tester);
      await tester.enterText(
        find.byKey(const ValueKey('register-name')),
        'Customer Test',
      );
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
    final repository = RecordingAuthRepository();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openRegister(tester, repository: repository);
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'rider@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-name')),
      'Customer Test',
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
    expect(repository.registeredEmail, 'rider@example.com');
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
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.canPop(), isFalse);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Login route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
