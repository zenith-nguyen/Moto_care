import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileAccountServiceProvider = Provider<ProfileAccountService>(
  (ref) => const UnavailableProfileAccountService(),
);

/// Implement with the centralized Dio client once account endpoints exist.
abstract class ProfileAccountService {
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> deleteAccount(String userId);
}

class ProfileAccountException implements Exception {
  const ProfileAccountException(this.message);
  final String message;
}

class UnavailableProfileAccountService implements ProfileAccountService {
  const UnavailableProfileAccountService();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw const ProfileAccountException(
      'Chưa thể đổi mật khẩu. Dịch vụ tài khoản chưa sẵn sàng.',
    );
  }

  @override
  Future<void> deleteAccount(String userId) async {
    throw const ProfileAccountException(
      'Chưa thể xóa tài khoản. Dịch vụ tài khoản chưa sẵn sàng.',
    );
  }
}
