import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/notifications/installation_id_store.dart';
import 'package:moto_care/core/notifications/push_registration_service.dart';
import 'package:moto_care/core/notifications/push_token_source.dart';
import 'package:moto_care/features/notifications/data/notifications_repository.dart';
import 'package:moto_care/features/notifications/domain/app_notification.dart';

void main() {
  test(
    'registers initial and rotated FCM tokens, then revokes on logout',
    () async {
      final tokens = FakePushTokenSource();
      final repository = FakeNotificationsRepository();
      final service = PushRegistrationService(
        tokens,
        FakeInstallationIdStore(),
        repository,
      );

      await service.activate();
      expect(repository.registeredTokens, ['initial-token']);

      tokens.rotate('rotated-token');
      await Future<void>.delayed(Duration.zero);
      expect(repository.registeredTokens, ['initial-token', 'rotated-token']);

      await service.deactivate();
      expect(repository.unregistered, ['installation-123456']);
      expect(tokens.deleted, isTrue);
    },
  );
}

class FakePushTokenSource implements PushTokenSource {
  final _changes = StreamController<String>.broadcast();
  bool deleted = false;

  @override
  bool get enabled => true;

  @override
  Stream<String> get tokenChanges => _changes.stream;

  @override
  Future<String?> requestToken() async => 'initial-token';

  @override
  Future<void> deleteToken() async {
    deleted = true;
  }

  void rotate(String token) => _changes.add(token);
}

class FakeInstallationIdStore implements InstallationIdStore {
  @override
  Future<String?> read() async => 'installation-123456';

  @override
  Future<String> readOrCreate() async => 'installation-123456';
}

class FakeNotificationsRepository implements NotificationsRepository {
  final registeredTokens = <String>[];
  final unregistered = <String>[];

  @override
  Future<void> registerDevice({
    required String installationId,
    required String fcmToken,
  }) async {
    registeredTokens.add(fcmToken);
  }

  @override
  Future<void> unregisterDevice(String installationId) async {
    unregistered.add(installationId);
  }

  @override
  Future<NotificationPage> list({
    int? cursor,
    int limit = 30,
    bool unreadOnly = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<DateTime> markAllRead() => throw UnimplementedError();

  @override
  Future<AppNotification> markRead(int notificationId) {
    throw UnimplementedError();
  }
}
