import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/app/router/app_router.dart';
import 'package:moto_care/core/network/api_failure.dart';
import 'package:moto_care/features/auth/application/session_controller.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/data/auth_repository.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';

import '../../support/memory_token_store.dart';

void main() {
  test('bootstraps to signed out when no token exists', () async {
    final container = createContainer(
      tokenStore: MemoryTokenStore(),
      repository: FakeAuthRepository(),
    );

    await container.read(sessionControllerProvider.notifier).bootstrap();

    expect(container.read(sessionControllerProvider), isA<SessionSignedOut>());
  });

  test('persists a successful sign-in and routes by server role', () async {
    final tokenStore = MemoryTokenStore();
    final repository = FakeAuthRepository(
      signInResult: AuthSession(
        accessToken: 'provider-token',
        user: testUser(role: AppRole.provider),
      ),
    );
    final container = createContainer(
      tokenStore: tokenStore,
      repository: repository,
    );
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.bootstrap();

    await controller.signIn(
      identity: 'provider@example.com',
      password: '12345678',
    );

    expect(tokenStore.token, 'provider-token');
    final state = container.read(sessionControllerProvider);
    expect(state, isA<SessionSignedIn>());
    expect((state as SessionSignedIn).session.user.role, AppRole.provider);
  });

  test('failed sign-in stays on login so the error remains visible', () async {
    final container = createContainer(
      tokenStore: MemoryTokenStore(),
      repository: FakeAuthRepository(failSignIn: true),
    );
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.bootstrap();

    await controller.signIn(
      identity: 'customer@example.com',
      password: 'wrong-password',
    );

    final state = container.read(sessionControllerProvider);
    expect(state, isA<SessionSignedOut>());
    expect((state as SessionSignedOut).failure, isA<ApiFailure>());
    expect(locationForSession(state), '/login');
  });

  test(
    'provider app clears a stale customer session during bootstrap',
    () async {
      final tokenStore = MemoryTokenStore('stale-customer-token');
      final container = createContainer(
        tokenStore: tokenStore,
        repository: FakeAuthRepository(),
        allowedRoles: const {AppRole.provider},
      );

      await container.read(sessionControllerProvider.notifier).bootstrap();

      expect(tokenStore.token, isNull);
      final state = container.read(sessionControllerProvider);
      expect(state, isA<SessionSignedOut>());
      expect(
        (state as SessionSignedOut).failure?.message,
        contains('tài khoản thợ'),
      );
    },
  );

  test(
    'provider app rejects a customer sign-in without saving its token',
    () async {
      final tokenStore = MemoryTokenStore();
      final container = createContainer(
        tokenStore: tokenStore,
        repository: FakeAuthRepository(),
        allowedRoles: const {AppRole.provider},
      );
      final controller = container.read(sessionControllerProvider.notifier);
      await controller.bootstrap();

      await controller.signIn(
        identity: 'customer@example.com',
        password: '12345678',
      );

      expect(tokenStore.token, isNull);
      final state = container.read(sessionControllerProvider);
      expect(state, isA<SessionSignedOut>());
      expect(locationForSession(state), '/login');
    },
  );

  test('provider app skips the customer welcome screen when signed out', () {
    expect(
      locationForSession(const SessionSignedOut(), providerOnly: true),
      '/login',
    );
    expect(locationForSession(const SessionSignedOut()), '/welcome');
  });
}

ProviderContainer createContainer({
  required MemoryTokenStore tokenStore,
  required AuthRepository repository,
  Set<AppRole>? allowedRoles,
}) {
  final container = ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(tokenStore),
      authRepositoryProvider.overrideWithValue(repository),
      if (allowedRoles != null)
        runtimeAllowedRolesProvider.overrideWithValue(allowedRoles),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

AppUser testUser({AppRole role = AppRole.customer}) {
  return AppUser(
    id: 1,
    name: 'MotoCare Test',
    email: 'test@example.com',
    phone: null,
    role: role,
    status: AppUserStatus.active,
  );
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.signInResult, this.failSignIn = false});

  final AuthSession? signInResult;
  final bool failSignIn;

  @override
  Future<AppUser> currentUser() async => testUser();

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<AuthSession> register({
    required String name,
    required String password,
    required AppRole role,
    String? email,
    String? phone,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {}

  @override
  Future<AuthSession> signIn({
    required String identity,
    required String password,
  }) async {
    if (failSignIn) {
      throw const ApiFailure(
        kind: ApiFailureKind.unauthorized,
        message: 'Thông tin đăng nhập không đúng.',
      );
    }
    return signInResult ??
        AuthSession(accessToken: 'customer-token', user: testUser());
  }
}
