import '../utils/format.dart';

/// Trạng thái xác minh do Admin quyết định — thợ chỉ xem, không tự bật/tắt.
enum VerificationStatus { verified, pending, rejected }

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
    this.phone = '',
    this.email = '',
    this.specialty = 'Sửa chữa tại chỗ',
    this.verificationStatus = VerificationStatus.pending,
    this.supportedVehicles = const ['Xe máy', 'Xe tay ga', 'Ô tô'],
    this.joinedAt,
    this.avatarAsset,
  });

  String name;
  String bio;
  String phone;
  String email;
  String specialty;
  List<String> supportedVehicles;
  final VerificationStatus verificationStatus;
  final DateTime? joinedAt;

  /// Asset path of the profile photo (null = default avatar).
  final String? avatarAsset;
  final String tierName; // "Bạc"
  final String nextTierName; // "Vàng"
  int tierOrders; // số đơn tính hạng trong kỳ
  final int nextTierTarget;
  int experienceYears;
  final int radiusKm;
  final double rating;
  final int ratingCount;
  String area;
  final List<Skill> skills;
  final List<VerificationDoc> documents;

  String get initials => initialsOf(name);
  int get ordersToNextTier =>
      (nextTierTarget - tierOrders).clamp(0, nextTierTarget);
  double get tierProgress => (tierOrders / nextTierTarget).clamp(0.0, 1.0);
}

/// Đơn cứu hộ mô phỏng được gửi tới thợ trong 30 giây.
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
    this.verificationCode = '2847',
    this.expiresAt,
    this.customerEmail,
    this.customerRating,
    this.customerRatingCount,
    this.customerVerified,
  });

  final String code; // "#MC2341"
  final String issue; // "Hết xăng"
  final String description; // nội dung sự cố khách mô tả
  final String vehicle; // "Honda Vision"
  final String plate; // "59-X1 123.45"
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final double? customerRating;
  final int? customerRatingCount;
  final bool? customerVerified;
  final String address;
  final double distanceKm;
  final int etaMinutes;
  final int price; // giá ban đầu
  final int platformFee; // chiết khấu sàn trên giá ban đầu
  final String verificationCode;
  final DateTime? expiresAt;
  String get orderId => code;
}

/// Chiết khấu sàn trên giá cuối: giữ chiết khấu gốc, phần phụ phí phát sinh chịu thêm 4,5%
/// (làm tròn nghìn). Vd: 74.000đ -> 140.000đ: 6.000đ + 3.000đ = 9.000đ.
int orderFee(
    {required int baseFee, required int basePrice, required int price}) {
  final extra = price - basePrice;
  if (extra <= 0) return baseFee;
  return baseFee + (extra * 0.045 / 1000).round() * 1000;
}

/// 5 bước xử lý đơn.
enum OrderStep { received, navigating, arrived, repairing, quoting, completed }

const List<String> orderStepLabels = [
  'Đã nhận',
  'Dẫn đường',
  'Đã đến',
  'Đang sửa',
  'Báo giá cuối',
  'Hoàn tất',
];

enum QuoteStatus { none, pending, accepted, rejected }

class MechanicService {
  MechanicService(this.name, {this.enabled = true, this.hasDemoOffers = true});
  final String name;
  bool enabled;

  /// Whether the demo dispatcher has an offer template for this service.
  /// Services without one never get an invented offer or price.
  final bool hasDemoOffers;
}

enum RevoNotificationType {
  emergency,
  message,
  quoteApproved,
  quoteRejected,
  order,
  income,
  withdrawal,
  certificate,
  review,
  system,
}

class RevoNotification {
  RevoNotification(this.title, this.body,
      {required this.orderRelated,
      String? id,
      RevoNotificationType? type,
      DateTime? time,
      this.detail,
      this.orderId,
      this.transactionId,
      this.offer,
      this.serviceIndex,
      this.demo = false,
      bool isRead = false})
      : id = id ?? 'notification-${_nextId++}',
        type = type ??
            (orderRelated
                ? RevoNotificationType.order
                : RevoNotificationType.system),
        time = time ?? DateTime.now(),
        read = isRead;
  static int _nextId = 1;
  final String id;
  final RevoNotificationType type;
  final String title, body;
  final String? detail;
  final bool orderRelated, demo;
  final DateTime time;
  final String? orderId, transactionId;
  final OrderOffer? offer;
  final int? serviceIndex;
  bool read;
  bool get isRead => read;

  /// Semantic action identifiers; resolveNotification selects the existing
  /// widget route. These are not Navigator.pushNamed registrations.
  String get targetRoute => switch (type) {
        RevoNotificationType.emergency => '/orders/request',
        RevoNotificationType.message => '/orders/chat',
        RevoNotificationType.quoteApproved ||
        RevoNotificationType.quoteRejected =>
          '/orders/quote',
        RevoNotificationType.order ||
        RevoNotificationType.review =>
          '/orders/detail',
        RevoNotificationType.income ||
        RevoNotificationType.withdrawal =>
          '/wallet/transaction',
        RevoNotificationType.certificate => '/account/documents',
        RevoNotificationType.system => '/notifications/detail',
      };
}

class QuoteLine {
  const QuoteLine(this.name, this.unitPrice, {this.quantity = 0});
  final String name;
  final int unitPrice;
  final int quantity;
  int get amount => unitPrice * quantity;
  QuoteLine withQuantity(int value) =>
      QuoteLine(name, unitPrice, quantity: value);
}

enum OtpChannel { sms, email }

enum OtpActionState { idle, sending, sent, verifying, verified, error }

class OrderOtpState {
  OtpChannel channel = OtpChannel.sms;
  OtpActionState status = OtpActionState.idle;
  String draft = '';
  String? message;
  DateTime? resendAvailableAt;
  bool get busy =>
      status == OtpActionState.sending || status == OtpActionState.verifying;
  int get cooldownSeconds => resendAvailableAt == null
      ? 0
      : (resendAvailableAt!.difference(DateTime.now()).inMilliseconds / 1000)
          .ceil()
          .clamp(0, 30);
}

/// Đơn thợ đang thực hiện.
class ActiveOrder {
  ActiveOrder(
      {required this.offer,
      required this.acceptedAt,
      required this.messages,
      List<QuoteLine> quoteDraft = const []})
      : quoteDraft = List.of(quoteDraft);

  final OrderOffer offer;
  final DateTime acceptedAt;
  final List<ChatMessage> messages;
  String get orderId => offer.orderId;

  final otp = OrderOtpState();
  OrderStep step = OrderStep.received;
  DateTime? navigationStartedAt;
  DateTime? arrivedAt;
  DateTime? otpVerifiedAt;
  DateTime? repairStartedAt;
  int repairStage = 0;
  final List<QuoteLine> quoteDraft;
  List<QuoteLine> submittedQuote = const [];
  List<QuoteLine> approvedQuote = const [];
  int approvedExtra = 0;
  bool demoReplyScheduled = false;
  DateTime? quoteResolvedAt;
  final List<TimelineEvent> quoteTimeline = [];
  int get draftExtra => quoteDraft.fold(0, (sum, line) => sum + line.amount);

  int? proposedPrice;
  String? quoteReason;
  DateTime? quoteSentAt;
  QuoteStatus quoteStatus = QuoteStatus.none;

  // Editing a rejected quote must not silently bypass the customer's decision.
  bool rejectedQuoteNeedsAction = false;

  bool get canAdvanceRepair {
    if (otpVerifiedAt == null || repairStartedAt == null || repairStage >= 3) {
      return false;
    }
    if (step != OrderStep.repairing && step != OrderStep.quoting) return false;
    // Inspection is independent of the proposed additional work.
    return repairStage == 0 ||
        (quoteStatus != QuoteStatus.pending && !rejectedQuoteNeedsAction);
  }

  String? get completionBlockedReason {
    if (step == OrderStep.completed) return 'Đơn hàng đã hoàn thành.';
    if (otpVerifiedAt == null || repairStartedAt == null) {
      return 'Cần xác nhận OTP trước khi sửa chữa.';
    }
    if (navigationStartedAt == null || arrivedAt == null) {
      return 'Cần hoàn tất dẫn đường và xác nhận đã đến nơi.';
    }
    if (quoteStatus == QuoteStatus.pending) {
      return 'Chờ khách duyệt báo giá trước khi sửa tiếp và bàn giao.';
    }
    if (rejectedQuoteNeedsAction) {
      return 'Khách từ chối: sửa báo giá hoặc chọn tiếp tục theo giá đã xác nhận.';
    }
    if (step != OrderStep.repairing) return 'Đơn chưa ở bước sửa chữa.';
    if (repairStage < 3) {
      return 'Hoàn tất đủ 3 bước kiểm tra, sửa chữa và bàn giao.';
    }
    return null;
  }

  int get finalPrice => offer.price + approvedExtra;

  int get finalFee => orderFee(
      baseFee: offer.platformFee, basePrice: offer.price, price: finalPrice);
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
    this.extraItems = const [],
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
  final List<QuoteLine> extraItems;
  String get orderId => code;

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

enum WithdrawStatus { pending, approved, failed }

/// Giao dịch ví. [amount] luôn là số dương — dấu +/- suy ra từ [type] khi hiển thị.
class WalletTransaction {
  WalletTransaction({
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
    this.resolvedAt,
  });

  final String code; // "#MC2341" hoặc "#RT0032"
  final String txnId; // "TX-88213"
  final TxType type;
  final int amount;
  final DateTime time;
  WithdrawStatus? withdrawStatus;
  DateTime? resolvedAt;
  final String? orderCode;
  final String? serviceName;
  final String? customerName;
  final String? customerPhone;
  final int finalPrice;
  final int platformFee;

  bool get isCredit => type == TxType.credit;
  int get balanceEffect => !isCredit && withdrawStatus == WithdrawStatus.failed
      ? 0
      : isCredit
          ? amount
          : -amount;
  String get title =>
      isCredit ? 'Đơn $orderCode hoàn thành' : 'Yêu cầu rút tiền';
}

enum MessageStatus { sending, sent, seen, failed }

class ChatMessage {
  ChatMessage({
    required this.fromMechanic,
    required this.time,
    this.text,
    this.isImage = false,
    this.imageVehicle,
    this.status = MessageStatus.sent,
  });

  final bool fromMechanic;
  final DateTime time;
  final String? text;
  final bool isImage;
  final String? imageVehicle;
  MessageStatus status;
}
