import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../chat/models/chat_conversation.dart';
import '../models/rescue_order.dart';
import '../providers/activity_provider.dart';
import '../widgets/order_dialogs.dart';
import '../widgets/order_summary.dart';

final activityUrlLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

abstract final class ActivityActions {
  static void feedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> openMap(
    BuildContext context,
    WidgetRef ref,
    RescueOrder order,
  ) => _launch(
    context,
    ref,
    Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': order.locationAddress,
    }),
    'Không thể mở bản đồ. Địa chỉ cứu hộ: ${order.locationAddress}',
  );

  static Future<void> call(
    BuildContext context,
    WidgetRef ref,
    RescueOrder order,
  ) async {
    final phone = order.providerPhone?.trim();
    if (phone == null || phone.isEmpty) return;
    await _launch(
      context,
      ref,
      Uri(scheme: 'tel', path: phone),
      'Không thể mở ứng dụng gọi điện. Số thợ: $phone',
    );
  }

  static Future<void> _launch(
    BuildContext context,
    WidgetRef ref,
    Uri uri,
    String fallback,
  ) async {
    final launcher = ref.read(activityUrlLauncherProvider);
    var opened = false;
    try {
      opened = await launcher(uri);
    } on Exception {
      opened = false;
    }
    if (context.mounted && !opened) feedback(context, fallback);
  }

  static void chat(BuildContext context, RescueOrder order) {
    if (!order.hasProvider) return;
    final name = order.providerName!.trim();
    final words = name.split(RegExp(r'\s+'));
    final initials = words.length > 1
        ? '${words[words.length - 2][0]}${words.last[0]}'
        : words.first[0];
    context.push(
      '/chat-detail',
      extra: ChatConversation(
        mechanicName: name,
        avatarInitials: initials,
        licensePlate: order.providerPlate ?? 'Chưa cập nhật biển số thợ',
        phoneNumber: order.providerPhone ?? '',
        status: switch (order.status) {
          RescueOrderStatus.repairing => RescueStatus.repairing,
          RescueOrderStatus.pending => RescueStatus.accepted,
          RescueOrderStatus.completed => RescueStatus.completed,
          _ => RescueStatus.arriving,
        },
        statusLabel: order.status.label,
        lastMessage:
            'Trao đổi về đơn ${order.orderCode}: ${order.serviceType.label}.',
        timeLabel: formatOrderDate(order.createdAt),
      ),
    );
  }

  static Future<T?> _dialog<T>(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    return showDialog<T>(
      context: context,
      builder: (context) => Theme(data: theme, child: child),
    );
  }

  static Future<void> cancel(
    BuildContext context,
    WidgetRef ref,
    RescueOrder order,
  ) async {
    final confirmed = await _dialog<bool>(
      context,
      AlertDialog(
        title: const Text('Hủy đơn cứu hộ?'),
        content: Text('Bạn muốn hủy đơn ${order.orderCode}?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Tiếp tục cứu hộ'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final cancelled = ref.read(activityProvider.notifier).cancelOrder(order.id);
    feedback(
      context,
      cancelled
          ? 'Đã hủy đơn trong phiên dùng thử.'
          : 'Đơn không còn ở trạng thái có thể hủy.',
    );
  }

  static Future<bool> rebook(
    BuildContext context,
    WidgetRef ref,
    RescueOrder order,
  ) async {
    if (ref.read(activityProvider).activeOrders.isNotEmpty) {
      feedback(
        context,
        'Bạn đang có đơn cứu hộ. Hãy hoàn tất hoặc hủy đơn trước khi đặt lại.',
      );
      return false;
    }
    final request = await _dialog<RebookRequest>(
      context,
      RebookOrderDialog(order: order),
    );
    if (!context.mounted || request == null) return false;
    try {
      ref
          .read(activityProvider.notifier)
          .rebookOrder(
            order.id,
            userVehicle: request.userVehicle,
            locationAddress: request.locationAddress,
          );
      feedback(context, 'Đã tạo đơn cứu hộ trong phiên dùng thử.');
      return true;
    } on StateError {
      feedback(
        context,
        'Không thể đặt lại. Vui lòng kiểm tra đơn đang diễn ra.',
      );
      return false;
    }
  }

  static Future<void> report(
    BuildContext context,
    WidgetRef ref,
    RescueOrder order,
  ) async {
    final message = await _dialog<String>(
      context,
      ReportOrderDialog(orderCode: order.orderCode),
    );
    if (!context.mounted || message == null) return;
    final saved = ref
        .read(activityProvider.notifier)
        .reportOrder(order.id, message);
    feedback(
      context,
      saved
          ? 'Đã lưu khiếu nại trong phiên dùng thử.'
          : 'Không thể lưu khiếu nại. Vui lòng thử lại.',
    );
  }
}
