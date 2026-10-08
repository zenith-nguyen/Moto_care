import 'app_user.dart';

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final user = json['user'];
    if (accessToken is! String || accessToken.isEmpty || user is! Map) {
      throw const FormatException('Invalid authentication response.');
    }

    return AuthSession(
      accessToken: accessToken,
      user: AppUser.fromJson(Map<String, dynamic>.from(user)),
    );
  }
}
