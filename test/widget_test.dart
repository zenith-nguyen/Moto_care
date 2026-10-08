import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/app/moto_care_app.dart';
import 'package:moto_care/features/auth/data/auth_repository.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';

import 'support/memory_token_store.dart';

void main() {
  testWidgets('boots into the temporary integration sign-in slot', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStoreProvider.overrideWithValue(MemoryTokenStore())],
        child: const MotoCareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nền tích hợp MotoCare'), findsOneWidget);
    expect(find.text('Đăng nhập để kiểm tra'), findsOneWidget);
  });

  testWidgets('restores an admin session into the admin integration slot', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(MemoryTokenStore('admin-token')),
          authRepositoryProvider.overrideWithValue(_AdminAuthRepository()),
        ],
        child: const MotoCareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã kết nối vai trò Admin'), findsOneWidget);
  });
}

class _AdminAuthRepository implements AuthRepository {
  static const user = AppUser(
    id: 99,
    name: 'Admin Test',
    email: 'admin@example.com',
    phone: null,
    role: AppRole.admin,
    status: AppUserStatus.active,
  );

  @override
  Future<AppUser> currentUser() async => user;

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
    return const AuthSession(accessToken: 'admin-token', user: user);
  }
}
