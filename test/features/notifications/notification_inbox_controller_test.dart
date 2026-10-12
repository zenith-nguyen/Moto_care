import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/features/notifications/application/notification_inbox_controller.dart';
import 'package:moto_care/features/notifications/data/notifications_repository.dart';
import 'package:moto_care/features/notifications/domain/app_notification.dart';

void main() {
  test('loads, paginates, and marks inbox notifications read', () async {
    final repository = FakeNotificationsRepository();
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(
      notificationInboxControllerProvider.future,
    );
    expect(initial.items.map((item) => item.id), [3]);
    expect(initial.unreadCount, 2);

    final controller = container.read(
      notificationInboxControllerProvider.notifier,
    );
    await controller.loadMore();
    expect(
      container
          .read(notificationInboxControllerProvider)
          .value!
          .items
          .map((item) => item.id),
      [3, 2],
    );

    await controller.markRead(3);
    final readOne = container.read(notificationInboxControllerProvider).value!;
    expect(readOne.items.first.readAt, isNotNull);
    expect(readOne.unreadCount, 1);

    await controller.markAllRead();
    final readAll = container.read(notificationInboxControllerProvider).value!;
    expect(readAll.unreadCount, 0);
    expect(readAll.items.every((item) => item.readAt != null), isTrue);
  });
}

class FakeNotificationsRepository implements NotificationsRepository {
  @override
  Future<NotificationPage> list({
    int? cursor,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    if (cursor == null) {
      return NotificationPage(
        items: [_notification(3)],
        nextCursor: 3,
        unreadCount: 2,
      );
    }
    return NotificationPage(
      items: [_notification(2)],
      nextCursor: null,
      unreadCount: 2,
    );
  }

  @override
  Future<AppNotification> markRead(int notificationId) async =>
      _notification(notificationId, readAt: DateTime.utc(2026, 10, 12));

  @override
  Future<DateTime> markAllRead() async => DateTime.utc(2026, 10, 12, 9);

  @override
  Future<void> registerDevice({
    required String installationId,
    required String fcmToken,
  }) async {}

  @override
  Future<void> unregisterDevice(String installationId) async {}
}

AppNotification _notification(int id, {DateTime? readAt}) {
  return AppNotification(
    id: id,
    type: AppNotificationType.system,
    title: 'MotoCare',
    body: 'Update',
    data: const {'route': 'home'},
    readAt: readAt,
    createdAt: DateTime.utc(2026, 10, 12, 8, id),
  );
}
