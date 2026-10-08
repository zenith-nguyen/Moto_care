import '../../../core/network/json_api.dart';
import '../domain/app_user.dart';
import '../domain/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({
    required String identity,
    required String password,
  });

  Future<AuthSession> register({
    required String name,
    required String password,
    required AppRole role,
    String? email,
    String? phone,
  });

  Future<AppUser> currentUser();

  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

class HttpAuthRepository implements AuthRepository {
  const HttpAuthRepository(this._api);

  final JsonApi _api;

  @override
  Future<AuthSession> signIn({
    required String identity,
    required String password,
  }) async {
    final response = await _api.postObject(
      '/auth/login',
      data: {'identity': identity.trim(), 'password': password},
    );
    return AuthSession.fromJson(response);
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String password,
    required AppRole role,
    String? email,
    String? phone,
  }) async {
    if (role == AppRole.admin) {
      throw const FormatException('Administrator accounts cannot register.');
    }
    final response = await _api.postObject(
      '/auth/register',
      data: {
        'name': name.trim(),
        'password': password,
        'role': role.wireValue,
        if (email?.trim().isNotEmpty ?? false) 'email': email!.trim(),
        if (phone?.trim().isNotEmpty ?? false) 'phone': phone!.trim(),
      },
    );
    return AuthSession.fromJson(response);
  }

  @override
  Future<AppUser> currentUser() async {
    final response = await _api.getObject('/users/me');
    return AppUser.fromJson(response);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _api.postObject(
      '/auth/password/forgot',
      data: {'email': email.trim()},
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.postObject(
      '/auth/password/reset',
      data: {
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
  }
}
