enum AdminOrderStatus {
  searching('Đang tìm thợ'),
  assigned('Đã phân công'),
  working('Đang làm'),
  completed('Hoàn thành'),
  cancelled('Đã hủy');

  const AdminOrderStatus(this.label);
  final String label;
}

enum AdminPaymentStatus {
  unpaid('Chưa thanh toán'),
  held('Đang giữ'),
  settled('Đã quyết toán'),
  refunded('Đã hoàn tiền');

  const AdminPaymentStatus(this.label);
  final String label;
}

enum AdminReviewStatus {
  pending('Chờ xử lý'),
  approved('Đã duyệt'),
  rejected('Đã từ chối');

  const AdminReviewStatus(this.label);
  final String label;
}

enum AdminMatchStatus {
  matched('Đã khớp'),
  pending('Đang chờ'),
  anomaly('Bất thường'),
  excluded('Không áp dụng');

  const AdminMatchStatus(this.label);
  final String label;
}

class AdminSession {
  const AdminSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.canManageAdmins = false,
  });
  final String id;
  final String name;
  final String email;
  final String role;

  /// Populated from a verified backend claim, never from a route or UI toggle.
  final bool canManageAdmins;
  bool get isAdmin => role == 'ADMIN';
  bool get isSuperAdmin => isAdmin && canManageAdmins;
}

class AdminDateRange {
  const AdminDateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is AdminDateRange && start == other.start && end == other.end;
  @override
  int get hashCode => Object.hash(start, end);
}

class AdminOrderFilter {
  const AdminOrderFilter({
    this.search = '',
    this.status,
    this.payment,
    this.range,
  });
  final String search;
  final AdminOrderStatus? status;
  final AdminPaymentStatus? payment;
  final AdminDateRange? range;
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.customer,
    required this.incident,
    required this.provider,
    required this.estimatedPrice,
    required this.finalPrice,
    required this.status,
    required this.payment,
    required this.createdAt,
    required this.collected,
    required this.refunded,
    required this.credited,
    required this.paymentId,
    this.warning,
    this.weatherFactor = 1,
    this.servicePrice = 0,
    this.travelPrice = 0,
    this.customerPosition = (10.7769, 106.7009),
    this.providerPosition = (10.7810, 106.6950),
    this.address = 'Quận 1, TP. Hồ Chí Minh',
    this.customerPhone,
    this.providerPhone,
    this.locationUpdatedAt,
    this.timeline = const [],
    this.offers = const [],
    this.payments = const [],
    this.chat = const [],
    this.dispute,
  });
  final String id;
  final String customer;
  final String incident;
  final String? provider;
  final int estimatedPrice;
  final int? finalPrice;
  final AdminOrderStatus status;
  final AdminPaymentStatus payment;
  final DateTime createdAt;
  final int collected;
  final int refunded;
  final int credited;
  final String? paymentId;
  final String? warning;
  final double weatherFactor;
  final int servicePrice;
  final int travelPrice;
  final (double, double) customerPosition;
  final (double, double)? providerPosition;
  final String address;
  final String? customerPhone;
  final String? providerPhone;
  final DateTime? locationUpdatedAt;
  final List<AdminTimelineEvent> timeline;
  final List<AdminOffer> offers;
  final List<AdminPaymentEvent> payments;
  final List<AdminChatMessage> chat;
  final String? dispute;

  AdminOrder withFinalPrice(
    int price, {
    String? resolution,
    DateTime? resolvedAt,
  }) => AdminOrder(
    id: id,
    customer: customer,
    incident: incident,
    provider: provider,
    estimatedPrice: estimatedPrice,
    finalPrice: price,
    status: status,
    payment: payment,
    createdAt: createdAt,
    collected: collected,
    refunded: refunded,
    credited: credited,
    paymentId: paymentId,
    warning: resolution == null
        ? warning
        : 'Giá đã được Admin chốt. Cần đối chiếu chênh lệch thanh toán.',
    weatherFactor: weatherFactor,
    servicePrice: servicePrice,
    travelPrice: travelPrice,
    customerPosition: customerPosition,
    providerPosition: providerPosition,
    address: address,
    customerPhone: customerPhone,
    providerPhone: providerPhone,
    locationUpdatedAt: locationUpdatedAt,
    timeline: resolvedAt == null
        ? timeline
        : List.unmodifiable([
            ...timeline,
            AdminTimelineEvent('Admin giải quyết tranh chấp giá', resolvedAt),
          ]),
    offers: offers,
    payments: payments,
    chat: chat,
    dispute: resolution ?? dispute,
  );
}

enum AdminOrderMilestone {
  created('Đã tạo'),
  accepted('Thợ nhận'),
  started('Bắt đầu'),
  completed('Hoàn thành');

  const AdminOrderMilestone(this.label);
  final String label;
}

class AdminTimelineEvent {
  const AdminTimelineEvent(this.label, this.at, {this.milestone});
  final String label;
  final DateTime at;
  final AdminOrderMilestone? milestone;
}

class AdminOffer {
  const AdminOffer(this.provider, this.price, this.label);
  final String provider;
  final int price;
  final String label;
}

class AdminPaymentEvent {
  const AdminPaymentEvent(this.id, this.label, this.amount, this.at);
  final String id;
  final String label;
  final int amount;
  final DateTime at;
}

class AdminChatMessage {
  const AdminChatMessage(this.sender, this.message, this.at);
  final String sender;
  final String message;
  final DateTime at;
}

class AdminMechanicPhoto {
  const AdminMechanicPhoto.asset(this.location, {required this.label})
    : isNetwork = false;
  const AdminMechanicPhoto.network(this.location, {required this.label})
    : isNetwork = true;

  final String location;
  final String label;
  final bool isNetwork;
}

class AdminProviderApplication {
  const AdminProviderApplication({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicle,
    required this.plate,
    required this.registeredAt,
    this.status = AdminReviewStatus.pending,
    this.reason,
    this.workshopAddress,
    this.citizenIdMasked,
    this.identityVerified = false,
    this.workshopPhoto,
    this.identityFrontPhoto,
    this.identityBackPhoto,
    this.portraitPhoto,
    this.additionalPhotos = const [],
  });
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicle;
  final String plate;
  final DateTime registeredAt;
  final AdminReviewStatus status;
  final String? reason;
  final String? workshopAddress;
  final String? citizenIdMasked;
  final bool identityVerified;
  final AdminMechanicPhoto? workshopPhoto;
  final AdminMechanicPhoto? identityFrontPhoto;
  final AdminMechanicPhoto? identityBackPhoto;
  final AdminMechanicPhoto? portraitPhoto;
  final List<AdminMechanicPhoto> additionalPhotos;
  AdminProviderApplication resolve(bool approve, String note) =>
      AdminProviderApplication(
        id: id,
        name: name,
        email: email,
        phone: phone,
        vehicle: vehicle,
        plate: plate,
        registeredAt: registeredAt,
        status: approve
            ? AdminReviewStatus.approved
            : AdminReviewStatus.rejected,
        reason: note,
        workshopAddress: workshopAddress,
        citizenIdMasked: citizenIdMasked,
        identityVerified: identityVerified,
        workshopPhoto: workshopPhoto,
        identityFrontPhoto: identityFrontPhoto,
        identityBackPhoto: identityBackPhoto,
        portraitPhoto: portraitPhoto,
        additionalPhotos: additionalPhotos,
      );
}

class AdminRefund {
  const AdminRefund({
    required this.id,
    required this.orderId,
    required this.customer,
    required this.amount,
    required this.reason,
    required this.sandboxTransaction,
    required this.source,
    this.status = AdminReviewStatus.pending,
  });
  final String id;
  final String orderId;
  final String customer;
  final int amount;
  final String reason;
  final String sandboxTransaction;
  final String source;
  final AdminReviewStatus status;
}

class AdminPriceDispute {
  const AdminPriceDispute({
    required this.id,
    required this.orderId,
    required this.originalPrice,
    required this.proposedPrice,
    required this.providerReason,
    required this.customerReply,
    this.status = AdminReviewStatus.pending,
    this.note,
  });
  final String id;
  final String orderId;
  final int originalPrice;
  final int proposedPrice;
  final String providerReason;
  final String customerReply;
  final AdminReviewStatus status;
  final String? note;
  int get difference => proposedPrice - originalPrice;
  AdminPriceDispute resolve(bool approve, String note) => AdminPriceDispute(
    id: id,
    orderId: orderId,
    originalPrice: originalPrice,
    proposedPrice: proposedPrice,
    providerReason: providerReason,
    customerReply: customerReply,
    note: note,
    status: approve ? AdminReviewStatus.approved : AdminReviewStatus.rejected,
  );
}

class AdminWalletEntry {
  const AdminWalletEntry(this.id, this.label, this.amount, this.at);
  final String id;
  final String label;
  final int amount;
  final DateTime at;
}

class AdminWallet {
  const AdminWallet({
    required this.providerId,
    required this.available,
    required this.locked,
    required this.history,
  });
  final String providerId;
  final int available;
  final int locked;
  final List<AdminWalletEntry> history;
  int get balance => available + locked;
}

class AdminWithdrawal {
  const AdminWithdrawal({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.amount,
    required this.createdAt,
    this.status = AdminReviewStatus.pending,
    this.note,
  });
  final String id;
  final String providerId;
  final String providerName;
  final int amount;
  final DateTime createdAt;
  final AdminReviewStatus status;
  final String? note;
  AdminWithdrawal resolve(bool approve, String note) => AdminWithdrawal(
    id: id,
    providerId: providerId,
    providerName: providerName,
    amount: amount,
    createdAt: createdAt,
    note: note,
    status: approve ? AdminReviewStatus.approved : AdminReviewStatus.rejected,
  );
}

class AdminWithdrawalSnapshot {
  const AdminWithdrawalSnapshot(this.request, this.wallet);
  final AdminWithdrawal request;
  final AdminWallet wallet;
}

class AdminReconciliation {
  const AdminReconciliation({
    required this.order,
    required this.status,
    this.reason,
  });
  final AdminOrder order;
  final AdminMatchStatus status;
  final String? reason;
}

class AdminMetric {
  const AdminMetric(this.label, this.value, {this.isMoney = false});
  final String label;
  final int value;
  final bool isMoney;
}

class AdminDashboardSummary {
  const AdminDashboardSummary(this.metrics);
  final List<AdminMetric> metrics;
}

class AdminTimeseriesPoint {
  const AdminTimeseriesPoint(
    this.day,
    this.orders,
    this.collected,
    this.refunded,
    this.credited,
  );
  final DateTime day;
  final int orders;
  final int collected;
  final int refunded;
  final int credited;
}

class AdminPendingCounts {
  const AdminPendingCounts(this.refunds, this.disputes, this.withdrawals);
  final int refunds;
  final int disputes;
  final int withdrawals;
  int get total => refunds + disputes + withdrawals;
}

class AdminException implements Exception {
  const AdminException(this.message, {this.forbidden = false});
  final String message;
  final bool forbidden;
  @override
  String toString() => message;
}
