import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/domain/order_status.dart';
import '../../notifications/application/notification_inbox_controller.dart';
import '../data/demo_chat_data.dart';
import '../models/chat_conversation.dart';
import '../models/admin_message.dart';

final chatConversationsAsyncProvider = FutureProvider<List<ChatConversation>>((
  ref,
) async {
  if (!ref.watch(runtimeApiIntegrationProvider)) {
    return List.unmodifiable(mockRescueConversations);
  }
  final orders = await ref.watch(ordersRepositoryProvider).listMine();
  final repository = ref.watch(messagesRepositoryProvider);
  final orderRepository = ref.watch(ordersRepositoryProvider);
  final result = <ChatConversation>[];
  for (final order in orders.where((item) => item.providerId != null)) {
    final messages = await repository.list(order.id);
    final contact = await _contactOrNull(orderRepository, order);
    final last = messages.isEmpty ? null : messages.last;
    final name = contact?.name ?? 'Thợ phụ trách #${order.providerId}';
    result.add(
      ChatConversation(
        orderId: order.id,
        customerId: order.customerId,
        mechanicName: name,
        avatarInitials: _initials(name),
        licensePlate: 'Đơn ${order.code}',
        phoneNumber: contact?.phone ?? '',
        status: _chatStatus(order.status),
        statusLabel: _statusLabel(order.status),
        lastMessage:
            last?.content ??
            (last?.image == null ? 'Chưa có tin nhắn' : 'Đã gửi một hình ảnh'),
        timeLabel: _timeLabel(last?.createdAt ?? order.createdAt),
      ),
    );
  }
  return List.unmodifiable(result);
});

final chatConversationsProvider = Provider<List<ChatConversation>>(
  (ref) => ref.watch(chatConversationsAsyncProvider).value ?? const [],
);

Future<ParticipantContact?> _contactOrNull(
  OrdersRepository repository,
  OrderSummary order,
) async {
  if (order.status.isTerminal) return null;
  try {
    return await repository.participantContact(order.id);
  } catch (_) {
    return null;
  }
}

RescueStatus _chatStatus(OrderStatus status) => switch (status) {
  OrderStatus.accepted || OrderStatus.arrived => RescueStatus.arriving,
  OrderStatus.inProgress ||
  OrderStatus.awaitingPriceApproval ||
  OrderStatus.priceDisputed ||
  OrderStatus.awaitingPayment ||
  OrderStatus.paid => RescueStatus.repairing,
  OrderStatus.completed ||
  OrderStatus.cancelled ||
  OrderStatus.refundPending ||
  OrderStatus.refunded => RescueStatus.completed,
  _ => RescueStatus.accepted,
};

String _statusLabel(OrderStatus status) => switch (status) {
  OrderStatus.awaitingPrepayment => 'Chờ thanh toán',
  OrderStatus.pendingMatch => 'Đang tìm thợ',
  OrderStatus.offered => 'Đã gửi đề nghị cho thợ',
  OrderStatus.accepted => 'Thợ đã nhận đơn',
  OrderStatus.arrived => 'Thợ đã đến',
  OrderStatus.inProgress => 'Đang sửa',
  OrderStatus.awaitingPriceApproval => 'Chờ duyệt giá',
  OrderStatus.priceDisputed => 'Đang xử lý tranh chấp giá',
  OrderStatus.awaitingPayment => 'Chờ thanh toán bổ sung',
  OrderStatus.paid => 'Đã thanh toán',
  OrderStatus.completed => 'Đã hoàn tất',
  OrderStatus.cancelled => 'Đã hủy',
  OrderStatus.refundPending => 'Đang hoàn tiền',
  OrderStatus.refunded => 'Đã hoàn tiền',
};

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts
      .skip(parts.length > 1 ? parts.length - 2 : 0)
      .map((part) => part[0])
      .join()
      .toUpperCase();
}

String _timeLabel(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}

final chatSupportMessagesProvider = Provider<List<AdminMessage>>(
  (ref) =>
      ref.watch(runtimeApiIntegrationProvider) ? const [] : demoSupportMessages,
);
final chatNotificationsProvider = Provider<List<AdminMessage>>((ref) {
  if (!ref.watch(runtimeApiIntegrationProvider)) {
    return demoAdminNotifications;
  }
  final inbox = ref.watch(notificationInboxControllerProvider).value;
  if (inbox == null) return const [];
  return List.unmodifiable(
    inbox.items.map(
      (item) => AdminMessage(
        title: item.title,
        message: item.body,
        time: _timeLabel(item.createdAt),
      ),
    ),
  );
});
