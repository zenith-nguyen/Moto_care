import '../../../core/network/json_api.dart';
import '../domain/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<void> registerDevice({
    required String installationId,
    required String fcmToken,
  });
  Future<void> unregisterDevice(String installationId);
  Future<NotificationPage> list({
    int? cursor,
    int limit = 30,
    bool unreadOnly = false,
  });
  Future<AppNotification> markRead(int notificationId);
  Future<DateTime> markAllRead();
}

class HttpNotificationsRepository implements NotificationsRepository {
  HttpNotificationsRepository(this._api);
  final JsonApi _api;

  @override
  Future<void> registerDevice({
    required String installationId,
    required String fcmToken,
  }) async {
    await _api.putObject(
      '/notifications/devices',
      data: {
        'installationId': installationId,
        'fcmToken': fcmToken,
        'platform': 'ANDROID',
      },
    );
  }

  @override
  Future<void> unregisterDevice(String installationId) async {
    await _api.deleteObject(
      '/notifications/devices/${Uri.encodeComponent(installationId)}',
    );
  }

  @override
  Future<NotificationPage> list({
    int? cursor,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    final response = await _api.getObject(
      '/notifications',
      queryParameters: {
        'limit': limit,
        'unreadOnly': unreadOnly,
        'cursor': ?cursor,
      },
    );
    return NotificationPage.fromJson(response);
  }

  @override
  Future<AppNotification> markRead(int notificationId) async {
    final response = await _api.patchObject(
      '/notifications/$notificationId/read',
    );
    return AppNotification.fromJson(response);
  }

  @override
  Future<DateTime> markAllRead() async {
    final response = await _api.patchObject('/notifications/read-all');
    final readAt = response['readAt'];
    if (readAt is! String) {
      throw const FormatException('Invalid mark-all-read response.');
    }
    return DateTime.parse(readAt);
  }
}
