import 'package:flutter/foundation.dart';

enum RescueStatus {
  arriving('Đang đến - 5 phút'),
  accepted('Thợ đã nhận đơn'),
  repairing('Đang sửa'),
  completed('Đã hoàn tất');

  const RescueStatus(this.label);

  final String label;
}

@immutable
class ChatConversation {
  const ChatConversation({
    required this.mechanicName,
    required this.avatarInitials,
    required this.licensePlate,
    required this.phoneNumber,
    required this.status,
    required this.lastMessage,
    required this.timeLabel,
    this.statusLabel,
  });

  final String mechanicName;
  final String avatarInitials;
  final String licensePlate;
  final String phoneNumber;
  final RescueStatus status;
  final String lastMessage;
  final String timeLabel;
  final String? statusLabel;
}
