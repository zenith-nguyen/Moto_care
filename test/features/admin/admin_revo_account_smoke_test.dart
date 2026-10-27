import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/features/admin/presentation/admin_shell.dart';
import 'package:moto_care/features/admin/revo/admin_account_screen.dart';
import 'package:moto_care/features/auth/application/session_controller.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';

void main() {
  testWidgets('revo admin account renders with profile and sign out', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runtimeApiIntegrationProvider.overrideWithValue(false),
          runtimeAllowedRolesProvider.overrideWithValue(const {
            AppRole.customer,
            AppRole.admin,
          }),
          sessionControllerProvider.overrideWith(_AdminSession.new),
        ],
        child: const MaterialApp(
          home: AdminShell(
            location: '/admin/account',
            child: RevoAdminAccountScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Tài khoản Quản trị'), findsOneWidget);
    expect(find.text('Cấu hình Phí & Hệ số'), findsOneWidget);
    expect(find.textContaining('QUẢN TRỊ VIÊN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _AdminSession extends SessionController {
  @override
  SessionState build() => const SessionSignedIn(
    AuthSession(
      accessToken: 'test-token',
      user: AppUser(
        id: 1,
        name: 'Quản trị REVO',
        email: 'admin@revo.vn',
        phone: '0900000000',
        role: AppRole.admin,
        status: AppUserStatus.active,
      ),
    ),
  );
}
