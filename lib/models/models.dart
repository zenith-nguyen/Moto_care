import 'package:flutter/material.dart';

/// Loại dịch vụ cứu hộ — quyết định icon hiển thị trong danh sách.
enum ServiceType { tire, battery, tow, oil, electric }

extension ServiceTypeX on ServiceType {
  IconData get icon => switch (this) {
        ServiceType.tire => Icons.adjust,
        ServiceType.battery => Icons.bolt_outlined,
        ServiceType.tow => Icons.local_shipping_outlined,
        ServiceType.oil => Icons.water_drop_outlined,
        ServiceType.electric => Icons.power_outlined,
      };
}

/// Trạng thái xác minh do Admin quyết định — thợ chỉ xem, không tự bật/tắt.
enum VerificationStatus { verified, pending, rejected }

/// Trạng thái hồ sơ đối tác của tài khoản đăng nhập.
enum AccountStatus { approved, pending, rejected }

class Skill {
  Skill({required this.name, required this.icon, required this.status});

  final String name;
  final IconData icon;
  VerificationStatus status;
}

class VerificationDoc {
  const VerificationDoc({required this.name, required this.icon, required this.status});

  final String name;
  final IconData icon;
  final VerificationStatus status;
}

class MechanicProfile {
  MechanicProfile({
    required this.name,
    required this.email,
    required this.bio,
    required this.tierName,
    required this.nextTierName,
    required this.tierOrders,
    required this.nextTierTarget,
    required this.experienceYears,
    required this.radiusKm,
    required this.rating,
    required this.ratingCount,
    required this.area,
    required this.skills,
    required this.documents,
  });

  String name;
  final String email;
  String bio;
  final String tierName; // "Bạc"
  final String nextTierName; // "Vàng"
  int tierOrders; // số đơn trong 30 ngày tính hạng
  final int nextTierTarget;
  final int experienceYears;
  final int radiusKm;
  final double rating;
  final int ratingCount;
  String area;
  final List<Skill> skills;
  final List<VerificationDoc> documents;

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
  int get ordersToNextTier => (nextTierTarget - tierOrders).clamp(0, nextTierTarget);
  double get tierProgress => (tierOrders / nextTierTarget).clamp(0.0, 1.0);
}

/// Đơn cứu hộ được hệ thống ghép tự động và gửi tới thợ (popup 15s).
class OrderOffer {
  const OrderOffer({
    required this.code,
    required this.service,
    required this.issue,
    required this.description,
    required this.vehicle,
    required this.plate,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.distanceKm,
    required this.etaMinutes,
    required this.price,
  });

  final String code; // "#MC105"
  final ServiceType service;
  final String issue; // "Hết bình, cần kích bình"
  final String description; // nội dung sự cố chi tiết
  final String vehicle; // "Honda Vario 150"
  final String plate; // "59S1-123.45"
  final String customerName;
  final String customerPhone;
  final String address;
  final double distanceKm;
  final int etaMinutes;
  final int price; // giá tạm tính

  int get platformFee => feeOf(price);
}

/// Chiết khấu sàn 10%.
int feeOf(int price) => (price * 0.1).round();

/// 5 bước xử lý đơn.
enum OrderStep { received, arrived, repairing, quoting, completed }

const List<String> orderStepLabels = [
  'Đã nhận đơn',
  'Đã đến nơi',
  'Đang sửa chữa',
  'Đề xuất giá',
  'Hoàn thành',
];

enum QuoteStatus { none, pending, accepted }

/// Đơn thợ đang thực hiện.
class ActiveOrder {
  ActiveOrder({required this.offer, required this.acceptedAt, required this.messages});

  final OrderOffer offer;
  final DateTime acceptedAt;
  final List<ChatMessage> messages;

  OrderStep step = OrderStep.received;
  DateTime? arrivedAt;
  DateTime? repairStartedAt;

  int? proposedPrice;
  String? quoteReason;
  DateTime? quoteSentAt;
  QuoteStatus quoteStatus = QuoteStatus.none;

  int get finalPrice => quoteStatus == QuoteStatus.accepted ? proposedPrice! : offer.price;
}

enum OrderStatus { active, completed, cancelled }

class TimelineEvent {
  const TimelineEvent(this.label, this.time);
  final String label;
  final DateTime time;
}

class OrderHistoryItem {
  OrderHistoryItem({
    required this.code,
    required this.service,
    required this.issue,
    required this.vehicle,
    required this.plate,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.status,
    required this.time,
    required this.initialPrice,
    required this.finalPrice,
    required this.timeline,
    this.extraReason,
    this.messages = const [],
    this.rating,
    this.ratingComment,
  });

  final String code;
  final ServiceType service;
  final String issue;
  final String vehicle;
  final String plate;
  final String customerName;
  final String customerPhone;
  final String address;
  final OrderStatus status;
  final DateTime time; // thời điểm hoàn thành / hủy
  final int initialPrice;
  final int finalPrice;
  final String? extraReason;
  final List<TimelineEvent> timeline;
  final List<ChatMessage> messages;

  /// Đánh giá thợ dành cho khách (null = chưa đánh giá).
  int? rating;
  String? ratingComment;

  int get extra => finalPrice - initialPrice;
  int get platformFee => feeOf(finalPrice);
  int get earning => finalPrice - platformFee;
}

enum TxType { credit, debit }

enum WithdrawStatus { pending, approved }

/// Giao dịch ví. [amount] luôn là số dương — dấu +/- suy ra từ [type] khi hiển thị.
class WalletTransaction {
  const WalletTransaction({
    required this.code,
    required this.txnId,
    required this.type,
    required this.amount,
    required this.time,
    this.withdrawStatus,
    this.orderCode,
    this.serviceName,
    this.customerName,
    this.customerPhone,
    this.customerArea,
    this.platformFee = 0,
  });

  final String code; // "#MC104" hoặc "#RT0032"
  final String txnId; // "TXN-88213049"
  final TxType type;
  final int amount;
  final DateTime time;
  final WithdrawStatus? withdrawStatus;
  final String? orderCode;
  final String? serviceName;
  final String? customerName;
  final String? customerPhone;
  final String? customerArea;
  final int platformFee;

  bool get isCredit => type == TxType.credit;
  String get title => isCredit ? 'Cộng tiền từ đơn hoàn thành' : 'Yêu cầu rút tiền';
}

enum MessageStatus { sending, sent, failed }

class ChatMessage {
  ChatMessage({
    required this.fromMechanic,
    required this.time,
    this.text,
    this.isImage = false,
    this.status = MessageStatus.sent,
  });

  final bool fromMechanic;
  final DateTime time;
  final String? text;
  final bool isImage;
  MessageStatus status;
}
