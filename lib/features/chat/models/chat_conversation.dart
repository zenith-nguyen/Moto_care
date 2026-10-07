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

const mockRescueConversations = [
  ChatConversation(
    mechanicName: 'Nguyễn Minh Tuấn',
    avatarInitials: 'MT',
    licensePlate: '59-X1 123.45',
    phoneNumber: '0900000001',
    status: RescueStatus.arriving,
    lastMessage: 'Mình sắp đến rồi. Bạn chờ ở vị trí đã ghim nhé!',
    timeLabel: '14:32',
  ),
  ChatConversation(
    mechanicName: 'Trần Quốc Bảo',
    avatarInitials: 'QB',
    licensePlate: '59-X1 123.45',
    phoneNumber: '0900000002',
    status: RescueStatus.completed,
    lastMessage: 'Xe đã được sửa xong. Cảm ơn bạn đã chọn MotoCare!',
    timeLabel: 'Hôm qua',
  ),
  ChatConversation(
    mechanicName: 'Lê Hoàng Nam',
    avatarInitials: 'HN',
    licensePlate: '51-F2 678.90',
    phoneNumber: '0900000003',
    status: RescueStatus.completed,
    lastMessage: 'Bạn nhớ kiểm tra áp suất lốp trước chuyến đi nhé.',
    timeLabel: '28/09',
  ),
  ChatConversation(
    mechanicName: 'Phạm Đức Huy',
    avatarInitials: 'DH',
    licensePlate: '51-F2 678.90',
    phoneNumber: '0900000004',
    status: RescueStatus.completed,
    lastMessage: 'Mình đã gửi thông tin bảo hành cho bạn rồi nhé.',
    timeLabel: '25/09',
  ),
];
