import 'package:moto_care/features/auth/data/auth_repository.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';

class RecordingAuthRepository implements AuthRepository {
  String? registeredName;
  String? registeredEmail;
  String? registeredPhone;
  AppRole? registeredRole;
  String? requestedResetEmail;
  String? resetEmail;
  String? resetCode;
  String? resetNewPassword;

  static const customer = AppUser(
    id: 123,
    name: 'Customer Test',
    email: 'rider@example.com',
    phone: '0912345678',
    role: AppRole.customer,
    status: AppUserStatus.active,
  );

  @override
  Future<AppUser> currentUser() async => customer;

  @override
  Future<AuthSession> register({
    required String name,
    required String password,
    required AppRole role,
    String? email,
    String? phone,
  }) async {
    registeredName = name;
    registeredEmail = email;
    registeredPhone = phone;
    registeredRole = role;
    return const AuthSession(accessToken: 'test-token', user: customer);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    requestedResetEmail = email;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    resetEmail = email;
    resetCode = code;
    resetNewPassword = newPassword;
  }

  @override
  Future<AuthSession> signIn({
    required String identity,
    required String password,
  }) async => const AuthSession(accessToken: 'test-token', user: customer);
}
