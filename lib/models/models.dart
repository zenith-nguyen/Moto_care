import '../utils/format.dart';

/// Trạng thái xác minh do Admin quyết định — thợ chỉ xem, không tự bật/tắt.
enum VerificationStatus { verified, pending, rejected }

/// Trạng thái hồ sơ đối tác của tài khoản đăng nhập.
enum AccountStatus { approved, pending, rejected }

class Skill {
  Skill({required this.name, required this.status});

  final String name;
  VerificationStatus status;
}

class VerificationDoc {
  const VerificationDoc({required this.name, required this.status});

  final String name;
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
  int tierOrders; // số đơn tính hạng trong kỳ
  final int nextTierTarget;
  final int experienceYears;
  final int radiusKm;
  final double rating;
  final int ratingCount;
  String area;
  final List<Skill> skills;
  final List<VerificationDoc> documents;

  String get initials => initialsOf(name);
  int get ordersToNextTier => (nextTierTarget - tierOrders).clamp(0, nextTierTarget);
  double get tierProgress => (tierOrders / nextTierTarget).clamp(0.0, 1.0);
}

/// Đơn cứu hộ được hệ thống ghép tự động và gửi tới thợ (popup 15s).
class OrderOffer {
  const OrderOffer({
    required this.code,
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
    required this.platformFee,
  });

  final String code; // "#MC2341"
  final String issue; // "Hết xăng"
  final String description; // nội dung sự cố khách mô tả
  final String vehicle; // "Honda Vision"
  final String plate; // "59-X1 123.45"
  final String customerName;
  final String customerPhone;
  final String address;
  final double distanceKm;
  final int etaMinutes;
  final int price; // giá ban đầu
  final int platformFee; // chiết khấu sàn trên giá ban đầu
}

/// Chiết khấu sàn trên giá cuối: giữ chiết khấu gốc, phần phụ phí phát sinh chịu thêm 4,5%
/// (làm tròn nghìn). Vd: 74.000đ -> 140.000đ: 6.000đ + 3.000đ = 9.000đ.
int orderFee({required int baseFee, required int basePrice, required int price}) {
  final extra = price - basePrice;
  if (extra <= 0) return baseFee;
  return baseFee + (extra * 0.045 / 1000).round() * 1000;
}

/// 5 bước xử lý đơn.
enum OrderStep { received, arrived, repairing, quoting, completed }

const List<String> orderStepLabels = [
  'Đã nhận',
  'Đã đến',
  'Đang sửa',
  'Báo giá cuối',
  'Hoàn tất',
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

  int get finalFee =>
      orderFee(baseFee: offer.platformFee, basePrice: offer.price, price: finalPrice);
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
    required this.fee,
    required this.timeline,
    this.extraReason,
    this.messages = const [],
    this.customerRating,
    this.customerReview,
    this.rating,
    this.ratingComment,
  });

  final String code;
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
  final int fee; // chiết khấu sàn
  final String? extraReason;
  final List<TimelineEvent> timeline;
  final List<ChatMessage> messages;

  /// Đánh giá của khách dành cho thợ.
  final int? customerRating;
  final String? customerReview;

  /// Đánh giá của thợ dành cho khách (null = chưa đánh giá).
  int? rating;
  String? ratingComment;

  int get extra => finalPrice - initialPrice;
  int get earning => status == OrderStatus.completed ? finalPrice - fee : 0;
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
    this.finalPrice = 0,
    this.platformFee = 0,
  });

  final String code; // "#MC2341" hoặc "#RT0032"
  final String txnId; // "TX-88213"
  final TxType type;
  final int amount;
  final DateTime time;
  final WithdrawStatus? withdrawStatus;
  final String? orderCode;
  final String? serviceName;
  final String? customerName;
  final String? customerPhone;
  final int finalPrice;
  final int platformFee;

  bool get isCredit => type == TxType.credit;
  String get title => isCredit ? 'Đơn $orderCode hoàn thành' : 'Yêu cầu rút tiền';
}

enum MessageStatus { sending, sent, seen, failed }

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
