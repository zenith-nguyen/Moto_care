import 'dart:async';

import '../../features/notifications/data/notifications_repository.dart';
import 'installation_id_store.dart';
import 'push_token_source.dart';

class PushRegistrationService {
  PushRegistrationService(
    this._tokens,
    this._installationIds,
    this._repository,
  );

  final PushTokenSource _tokens;
  final InstallationIdStore _installationIds;
  final NotificationsRepository _repository;
  StreamSubscription<String>? _tokenSubscription;
  bool _active = false;

  Future<void> activate() async {
    if (!_tokens.enabled) return;
    _active = true;
    final token = await _tokens.requestToken();
    if (!_active || token == null || token.isEmpty) return;
    await _register(token);
    await _tokenSubscription?.cancel();
    _tokenSubscription = _tokens.tokenChanges.listen((newToken) {
      if (_active && newToken.isNotEmpty) {
        unawaited(_register(newToken).catchError((_) {}));
      }
    });
  }

  Future<void> deactivate() async {
    if (!_active) return;
    _active = false;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    if (!_tokens.enabled) return;
    final installationId = await _installationIds.read();
    try {
      if (installationId != null) {
        await _repository.unregisterDevice(installationId);
      }
    } finally {
      await _tokens.deleteToken();
    }
  }

  Future<void> _register(String token) async {
    final installationId = await _installationIds.readOrCreate();
    await _repository.registerDevice(
      installationId: installationId,
      fcmToken: token,
    );
  }

  Future<void> dispose() async {
    _active = false;
    await _tokenSubscription?.cancel();
  }
}
