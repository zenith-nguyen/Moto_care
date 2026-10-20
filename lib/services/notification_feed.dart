import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/format.dart';

enum NotificationFilter {
  all,
  unread,
  read,
  orders,
  messages,
  payments,
  system
}

const notificationFilterLabels = [
  'Tất cả',
  'Chưa đọc',
  'Đã đọc',
  'Đơn hàng',
  'Tin nhắn',
  'Thanh toán',
  'Hệ thống'
];

bool matchesNotification(RevoNotification n, NotificationFilter filter) =>
    switch (filter) {
      NotificationFilter.all => true,
      NotificationFilter.unread => !n.read,
      NotificationFilter.read => n.read,
      NotificationFilter.messages => n.type == RevoNotificationType.message,
      NotificationFilter.payments => n.type == RevoNotificationType.income ||
          n.type == RevoNotificationType.withdrawal,
      NotificationFilter.system => n.type == RevoNotificationType.system ||
          n.type == RevoNotificationType.certificate,
      NotificationFilter.orders => switch (n.type) {
          RevoNotificationType.emergency ||
          RevoNotificationType.order ||
          RevoNotificationType.quoteApproved ||
          RevoNotificationType.quoteRejected ||
          RevoNotificationType.review =>
            true,
          _ => false,
        },
    };

class NotificationGroup {
  const NotificationGroup(this.label, this.items);
  final String label;
  final List<RevoNotification> items;
}

List<NotificationGroup> groupNotifications(
    Iterable<RevoNotification> source, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final monday =
      DateTime(today.year, today.month, today.day - today.weekday + 1);
  final lastMonday = DateTime(monday.year, monday.month, monday.day - 7);
  final buckets = <String, List<RevoNotification>>{};
  final sorted = source.toList()..sort((a, b) => b.time.compareTo(a.time));
  for (final n in sorted) {
    final time = n.time.toLocal();
    final label = !time.isBefore(today)
        ? 'Mới'
        : !time.isBefore(yesterday)
            ? 'Hôm qua'
            : !time.isBefore(monday)
                ? 'Tuần này'
                : !time.isBefore(lastMonday)
                    ? 'Tuần trước'
                    : 'Trước đó';
    buckets.putIfAbsent(label, () => []).add(n);
  }
  return [
    for (final entry in buckets.entries)
      NotificationGroup(entry.key, List.unmodifiable(entry.value))
  ];
}

String notificationTime(DateTime timestamp, DateTime now) {
  final time = timestamp.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final age = now.difference(time);
  if (age.isNegative) return '${formatDM(time)} · ${formatHm(time)}';
  if (!time.isBefore(today)) {
    if (age.inMinutes < 1) return 'Vừa xong';
    if (age.inMinutes < 60) return '${age.inMinutes} phút trước';
    return '${age.inHours} giờ trước';
  }
  if (!time.isBefore(yesterday)) return 'Hôm qua · ${formatHm(time)}';
  final monday =
      DateTime(today.year, today.month, today.day - today.weekday + 1);
  final lastMonday = DateTime(monday.year, monday.month, monday.day - 7);
  if (!time.isBefore(lastMonday)) {
    return '${time.weekday == 7 ? 'CN' : 'Thứ ${time.weekday + 1}'} · ${formatHm(time)}';
  }
  return '${formatDM(time)}/${time.year} · ${formatHm(time)}';
}

enum NotificationAction {
  request,
  activeOrder,
  quote,
  chat,
  history,
  transaction,
  documents,
  reviews,
  detail,
  unavailable
}

class NotificationDestination {
  const NotificationDestination(this.action,
      {this.active, this.order, this.transaction, this.offer, this.reason});
  final NotificationAction action;
  final ActiveOrder? active;
  final OrderHistoryItem? order;
  final WalletTransaction? transaction;
  final OrderOffer? offer;
  final String? reason;
}

/// Resolve fresh state on every tap. Reading an event cannot approve a quote,
/// accept an offer, credit a wallet or change the selected shell tab.
NotificationDestination resolveNotification(
    RevoNotification n, AppState state, DateTime now) {
  NotificationDestination unavailable(String reason) =>
      NotificationDestination(NotificationAction.unavailable, reason: reason);
  final active = n.orderId != null && state.activeOrder?.orderId == n.orderId
      ? state.activeOrder
      : null;
  final orders =
      state.history.where((o) => n.orderId != null && o.orderId == n.orderId);
  final order = orders.isEmpty ? null : orders.first;
  switch (n.type) {
    case RevoNotificationType.emergency:
      if (active != null) {
        return NotificationDestination(NotificationAction.activeOrder,
            active: active);
      }
      if (order != null) {
        return NotificationDestination(NotificationAction.history,
            order: order);
      }
      if (state.transactions
          .any((tx) => tx.isCredit && tx.orderCode == n.orderId)) {
        return unavailable('Đơn này đã hoàn tất; không thể nhận lại.');
      }
      final offer = n.offer;
      if (offer == null || n.orderId == null || offer.orderId != n.orderId) {
        return unavailable('Không còn thông tin yêu cầu cứu hộ này.');
      }
      if (offer.expiresAt == null || !now.isBefore(offer.expiresAt!)) {
        return unavailable(
            'Đơn đã hết hạn. Yêu cầu này không còn khả dụng để nhận.');
      }
      if (state.activeOrder != null) {
        return unavailable(
            'Bạn đang xử lý một đơn khác. Hãy hoàn thành đơn hiện tại trước.');
      }
      if (!state.demoEnabled || !state.sessionActive) {
        return unavailable('Phiên nhận đơn không khả dụng.');
      }
      if (!state.isOnline || !state.networkAvailable || !state.gpsEnabled) {
        return unavailable(
            'Cần trực tuyến, có kết nối mạng và bật định vị để nhận đơn.');
      }
      final index = n.serviceIndex;
      if (index != null &&
          (index < 0 ||
              index >= state.services.length ||
              !state.services[index].enabled)) {
        return unavailable('Dịch vụ của yêu cầu này đang tắt trong hồ sơ thợ.');
      }
      return NotificationDestination(NotificationAction.request, offer: offer);
    case RevoNotificationType.message:
      if (active != null) {
        return NotificationDestination(NotificationAction.chat, active: active);
      }
      if (order != null) {
        return NotificationDestination(NotificationAction.chat, order: order);
      }
      return unavailable(
          'Không tìm thấy cuộc trò chuyện của đơn ${n.orderId ?? 'này'}.');
    case RevoNotificationType.quoteApproved:
    case RevoNotificationType.quoteRejected:
      if (active != null && active.repairStartedAt != null) {
        return NotificationDestination(NotificationAction.quote,
            active: active);
      }
      if (order != null) {
        return NotificationDestination(NotificationAction.history,
            order: order);
      }
      return unavailable(
          'Không còn dữ liệu báo giá của đơn ${n.orderId ?? 'này'}.');
    case RevoNotificationType.income:
    case RevoNotificationType.withdrawal:
      final transactions = state.transactions.where((tx) =>
          tx.txnId == n.transactionId &&
          (n.type == RevoNotificationType.income
              ? tx.isCredit
              : !tx.isCredit) &&
          (n.orderId == null || (tx.orderCode ?? tx.code) == n.orderId));
      if (transactions.isEmpty) {
        return unavailable(
            'Không tìm thấy giao dịch tương ứng. Số dư Ví không thay đổi.');
      }
      return NotificationDestination(NotificationAction.transaction,
          transaction: transactions.first);
    case RevoNotificationType.certificate:
      return const NotificationDestination(NotificationAction.documents);
    case RevoNotificationType.review:
      if (order != null) {
        return NotificationDestination(NotificationAction.history,
            order: order);
      }
      if (n.orderId == null) {
        return const NotificationDestination(NotificationAction.reviews);
      }
      return unavailable('Không còn chi tiết đơn được đánh giá.');
    case RevoNotificationType.order:
      if (active != null) {
        return NotificationDestination(NotificationAction.activeOrder,
            active: active);
      }
      if (order != null) {
        return NotificationDestination(NotificationAction.history,
            order: order);
      }
      return unavailable('Không còn dữ liệu của đơn ${n.orderId ?? 'này'}.');
    case RevoNotificationType.system:
      return const NotificationDestination(NotificationAction.detail);
  }
}
