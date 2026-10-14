import '../domain/app_notification.dart';

class NotificationInboxState {
  const NotificationInboxState({
    required this.items,
    required this.nextCursor,
    required this.unreadCount,
    this.isLoadingMore = false,
    this.lastFailure,
  });

  final List<AppNotification> items;
  final int? nextCursor;
  final int unreadCount;
  final bool isLoadingMore;
  final Object? lastFailure;

  NotificationInboxState copyWith({
    List<AppNotification>? items,
    Object? nextCursor = _unchanged,
    int? unreadCount,
    bool? isLoadingMore,
    Object? lastFailure = _unchanged,
  }) {
    return NotificationInboxState(
      items: items ?? this.items,
      nextCursor: identical(nextCursor, _unchanged)
          ? this.nextCursor
          : nextCursor as int?,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
