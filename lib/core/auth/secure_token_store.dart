import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'motocare.access_token.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _accessTokenKey);

  @override
  Future<void> write(String token) {
    if (token.trim().isEmpty) {
      throw const FormatException('Access token cannot be empty.');
    }
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<void> clear() => _storage.delete(key: _accessTokenKey);
}
