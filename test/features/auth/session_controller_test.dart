import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
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
}

ProviderContainer createContainer({
  required MemoryTokenStore tokenStore,
  required AuthRepository repository,
}) {
  final container = ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(tokenStore),
      authRepositoryProvider.overrideWithValue(repository),
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
  FakeAuthRepository({this.signInResult});

  final AuthSession? signInResult;

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
    return signInResult ??
        AuthSession(accessToken: 'customer-token', user: testUser());
  }
}
