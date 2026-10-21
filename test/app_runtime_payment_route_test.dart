import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/router/app_router.dart';
import 'package:moto_care/features/auth/application/session_controller.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';

class _CustomerSession extends SessionController {
  @override
  SessionState build() => SessionSignedIn(
    AuthSession(
      accessToken: 'test',
      user: const AppUser(
        id: 7,
        name: 'Customer',
        email: 'customer@example.test',
        phone: null,
        role: AppRole.customer,
        status: AppUserStatus.active,
      ),
    ),
  );
}

void main() {
  test('customer payment route stays on bank transfer instead of home', () {
    final container = ProviderContainer(
      overrides: [sessionControllerProvider.overrideWith(_CustomerSession.new)],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go('/bank-transfer?id=42');
    expect(router.routeInformationProvider.value.uri.path, '/bank-transfer');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['id'],
      '42',
    );
  });
}
