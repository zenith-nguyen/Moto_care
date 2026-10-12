import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/notifications/data/notifications_repository.dart';

import '../../support/recording_json_api.dart';

void main() {
  test('registers an Android installation without exposing token handling to widgets', () async {
    final api = RecordingJsonApi();
    final repository = HttpNotificationsRepository(api);

    await repository.registerDevice(
      installationId: 'installation-1234567890',
      fcmToken: 'fcm-token-12345678901234567890',
    );

    expect(api.lastMethod, 'PUT');
    expect(api.lastPath, '/notifications/devices');
    expect(api.lastData, {
      'installationId': 'installation-1234567890',
      'fcmToken': 'fcm-token-12345678901234567890',
      'platform': 'ANDROID',
    });
  });

  test('parses the cursor inbox and preserves route data as strings', () async {
    final api = RecordingJsonApi()
      ..objectResponse = {
        'items': [
          {
            'id': 4,
            'type': 'PROVIDER_NEARBY',
            'title': 'Thợ sắp đến',
            'body': 'Thợ đang ở gần.',
            'data': {'route': 'order_tracking', 'orderId': '8'},
            'readAt': null,
            'createdAt': '2026-10-12T10:00:00.000Z',
          },
        ],
        'nextCursor': null,
        'unreadCount': 1,
      };
    final page = await HttpNotificationsRepository(api).list(unreadOnly: true);

    expect(page.unreadCount, 1);
    expect(page.items.single.data['orderId'], '8');
    expect(api.lastQueryParameters, {'limit': 30, 'unreadOnly': true});
  });

  test('uses the backend timestamp when all notifications are marked read', () async {
    final api = RecordingJsonApi()
      ..objectResponse = {
        'updatedCount': 2,
        'readAt': '2026-10-12T09:00:00.000Z',
      };

    final readAt = await HttpNotificationsRepository(api).markAllRead();

    expect(readAt, DateTime.utc(2026, 10, 12, 9));
    expect(api.lastMethod, 'PATCH');
    expect(api.lastPath, '/notifications/read-all');
  });
}
