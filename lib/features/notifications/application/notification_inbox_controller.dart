import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../domain/app_notification.dart';
import 'notification_inbox_state.dart';

final notificationInboxControllerProvider =
    AsyncNotifierProvider<NotificationInboxController, NotificationInboxState>(
      NotificationInboxController.new,
    );

class NotificationInboxController
    extends AsyncNotifier<NotificationInboxState> {
  @override
  Future<NotificationInboxState> build() async {
    final page = await ref.read(notificationsRepositoryProvider).list();
    return NotificationInboxState(
      items: page.items,
      nextCursor: page.nextCursor,
      unreadCount: page.unreadCount,
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    try {
      final page = await ref.read(notificationsRepositoryProvider).list();
      state = AsyncData(
        NotificationInboxState(
          items: page.items,
          nextCursor: page.nextCursor,
          unreadCount: page.unreadCount,
        ),
      );
    } catch (error) {
      state = AsyncData(current.copyWith(lastFailure: error));
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        current.isLoadingMore ||
        current.nextCursor == null) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true, lastFailure: null));
    try {
      final page = await ref
          .read(notificationsRepositoryProvider)
          .list(cursor: current.nextCursor);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          unreadCount: page.unreadCount,
          isLoadingMore: false,
          lastFailure: null,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, lastFailure: error),
      );
    }
  }

  Future<void> markRead(int notificationId) async {
    final current = state.value;
    if (current == null) return;
    AppNotification? existing;
    for (final item in current.items) {
      if (item.id == notificationId) {
        existing = item;
        break;
      }
    }
    if (existing == null || existing.readAt != null) return;
    try {
      final updated = await ref
          .read(notificationsRepositoryProvider)
          .markRead(notificationId);
      state = AsyncData(
        current.copyWith(
          items: current.items
              .map((item) => item.id == notificationId ? updated : item)
              .toList(growable: false),
          unreadCount: current.unreadCount > 0 ? current.unreadCount - 1 : 0,
          lastFailure: null,
        ),
      );
    } catch (error) {
      state = AsyncData(current.copyWith(lastFailure: error));
    }
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.unreadCount == 0) return;
    try {
      final readAt = await ref
          .read(notificationsRepositoryProvider)
          .markAllRead();
      state = AsyncData(
        current.copyWith(
          items: current.items
              .map(
                (item) =>
                    item.readAt == null ? item.copyWithReadAt(readAt) : item,
              )
              .toList(growable: false),
          unreadCount: 0,
          lastFailure: null,
        ),
      );
    } catch (error) {
      state = AsyncData(current.copyWith(lastFailure: error));
    }
  }
}

extension on AppNotification {
  AppNotification copyWithReadAt(DateTime value) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      readAt: value,
      createdAt: createdAt,
    );
  }
}
