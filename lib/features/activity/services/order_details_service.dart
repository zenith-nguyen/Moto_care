import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../../profile/models/user_profile.dart';
import '../models/order_details.dart';
import '../models/rescue_order.dart';

class OrderDetailsService {
  const OrderDetailsService();

  int _rank(RescueOrderStatus status) => switch (status) {
    RescueOrderStatus.pending => 0,
    RescueOrderStatus.enRoute => 1,
    RescueOrderStatus.repairing => 2,
    RescueOrderStatus.completed => 3,
    RescueOrderStatus.cancelled => -1,
  };

  String _description(RescueOrderStatus status) => switch (status) {
    RescueOrderStatus.pending => 'Yêu cầu cứu hộ đã được hệ thống ghi nhận.',
    RescueOrderStatus.enRoute =>
      'Thợ đã nhận đơn và đang di chuyển đến vị trí của bạn.',
    RescueOrderStatus.repairing =>
      'Thợ đã đến và đang kiểm tra, xử lý sự cố của xe.',
    RescueOrderStatus.completed => 'Dịch vụ cứu hộ đã hoàn thành.',
    RescueOrderStatus.cancelled => 'Đơn cứu hộ đã được hủy.',
  };

  OrderDetails resolve(RescueOrder order, UserProfile profile) {
    final cancelled = order.status == RescueOrderStatus.cancelled;
    final rank = _rank(order.status);
    final events = order.statusEvents
        .where(
          (event) =>
              !event.occurredAt.isBefore(order.createdAt) &&
              (cancelled || _rank(event.status) <= rank) &&
              (cancelled || event.status != RescueOrderStatus.cancelled),
        )
        .toList();
    if (!events.any((event) => event.status == RescueOrderStatus.pending)) {
      events.add(
        RescueOrderEvent(
          status: RescueOrderStatus.pending,
          occurredAt: order.createdAt,
        ),
      );
    }
    events.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final times = <RescueOrderStatus, DateTime>{};
    for (final event in events) {
      times.putIfAbsent(event.status, () => event.occurredAt);
    }
    final lastKnownRank = cancelled
        ? events.fold<int>(
            0,
            (highest, event) =>
                _rank(event.status) > highest ? _rank(event.status) : highest,
          )
        : rank;
    final timeline = <OrderTimelineEntry>[];
    // Old orders carry only their creation timestamp. Never invent the time
    // of an accepted/arriving/repairing/completed transition.
    if (order.status != RescueOrderStatus.pending &&
        !times.containsKey(order.status)) {
      timeline.add(
        OrderTimelineEntry(
          time: '—',
          date: 'Chưa có mốc giờ',
          description: _description(order.status),
          isCurrent: true,
          isCancelled: cancelled,
        ),
      );
    }
    for (final event in events.reversed) {
      timeline.add(
        OrderTimelineEntry(
          time: DateFormat('HH:mm').format(event.occurredAt.toLocal()),
          date: DateFormat('dd/MM/yyyy').format(event.occurredAt.toLocal()),
          description: event.description.trim().isEmpty
              ? _description(event.status)
              : event.description.trim(),
          isCurrent: timeline.isEmpty,
          isCancelled: event.status == RescueOrderStatus.cancelled,
        ),
      );
    }
    final name = order.providerName?.trim() ?? '';
    final words = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final hasSnapshot =
        order.requesterName.trim().isNotEmpty ||
        order.requesterPhone.trim().isNotEmpty;
    final requesterName = hasSnapshot ? order.requesterName : profile.fullName;
    final requesterPhone = hasSnapshot
        ? order.requesterPhone
        : profile.phoneNumber;
    const labels = ['Đã nhận đơn', 'Thợ đang đến', 'Đang sửa', 'Hoàn thành'];
    const statuses = [
      RescueOrderStatus.pending,
      RescueOrderStatus.enRoute,
      RescueOrderStatus.repairing,
      RescueOrderStatus.completed,
    ];
    return OrderDetails(
      order: order,
      statusLabel: switch (order.status) {
        RescueOrderStatus.pending =>
          order.hasProvider ? 'Đã nhận đơn' : 'Đang tìm thợ',
        RescueOrderStatus.enRoute => 'Thợ đang đến',
        RescueOrderStatus.repairing => 'Đang sửa',
        RescueOrderStatus.completed => 'Hoàn thành',
        RescueOrderStatus.cancelled => 'Đã hủy',
      },
      requesterName: requesterName.trim().isEmpty
          ? 'Chưa cập nhật tên'
          : requesterName.trim(),
      requesterPhone: requesterPhone.trim().isEmpty
          ? 'Chưa cập nhật số điện thoại'
          : requesterPhone.trim(),
      mechanicName: name.isNotEmpty
          ? name
          : order.status == RescueOrderStatus.pending
          ? 'Đang tìm thợ gần bạn'
          : 'Chưa có thông tin thợ',
      mechanicInitials: words.isEmpty
          ? ''
          : words.length == 1
          ? words.first.characters.first.toUpperCase()
          : '${words[words.length - 2].characters.first}${words.last.characters.first}'
                .toUpperCase(),
      mechanicPlate: order.providerPlate?.trim().isNotEmpty == true
          ? order.providerPlate!.trim()
          : 'Chưa cập nhật biển số',
      steps: [
        for (var index = 0; index < labels.length; index++)
          RescueProgressStep(
            label: labels[index],
            state: index > lastKnownRank
                ? RescueProgressState.upcoming
                : cancelled || index < rank || rank == 3
                ? RescueProgressState.done
                : RescueProgressState.active,
            time: times[statuses[index]] == null
                ? '—'
                : DateFormat('HH:mm').format(times[statuses[index]]!.toLocal()),
          ),
      ],
      timeline: timeline,
    );
  }
}
