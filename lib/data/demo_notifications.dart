import '../models/models.dart';
import '../utils/format.dart';
import 'home_catalog.dart';

/// Demo-only events joined to the actual fixture orders/ledger/profile. The
/// supplied design's names, amounts and approval text are not copied as facts.
List<RevoNotification> demoNotifications({
  required MechanicProfile profile,
  required List<OrderHistoryItem> history,
  required List<WalletTransaction> transactions,
  required DateTime now,
}) {
  final result = <RevoNotification>[];
  final request = demoHomeRequests(now).first;
  final o = request.offer;
  final offer = OrderOffer(
      code: o.code,
      issue: o.issue,
      description: o.description,
      vehicle: o.vehicle,
      plate: o.plate,
      customerName: o.customerName,
      customerPhone: o.customerPhone,
      address: o.address,
      distanceKm: o.distanceKm,
      etaMinutes: o.etaMinutes,
      price: o.price,
      platformFee: o.platformFee,
      verificationCode: o.verificationCode,
      expiresAt: request.availableUntil);
  result.add(RevoNotification(
      'Đơn cứu hộ khẩn mới', 'Đơn ${o.code} · ${o.issue} · ${o.address}',
      id: 'demo-request-${o.code}',
      type: RevoNotificationType.emergency,
      orderRelated: true,
      orderId: o.code,
      offer: offer,
      serviceIndex: 0,
      time: request.requestedAt,
      demo: true,
      detail: 'Vui lòng xác nhận khi yêu cầu còn hiệu lực.'));
  final pending = transactions
      .where((t) => !t.isCredit && t.withdrawStatus == WithdrawStatus.pending);
  if (pending.isNotEmpty) {
    final tx = pending.first;
    result.add(RevoNotification(
        'Yêu cầu rút tiền đã tiếp nhận', '${formatVnd(tx.amount)} · ${tx.code}',
        id: 'demo-withdraw-${tx.txnId}',
        type: RevoNotificationType.withdrawal,
        orderRelated: false,
        transactionId: tx.txnId,
        time: tx.time,
        demo: true,
        detail: 'Mở giao dịch để xem trạng thái xử lý hiện tại.'));
  }
  final credits = transactions.where((t) => t.isCredit).toList()
    ..sort((a, b) => b.time.compareTo(a.time));
  if (credits.isNotEmpty) {
    final tx = credits.first;
    result.add(RevoNotification('Thu nhập đã cộng vào Ví',
        '+${formatVnd(tx.amount)} từ đơn ${tx.orderCode ?? tx.code}',
        id: 'demo-income-${tx.txnId}',
        type: RevoNotificationType.income,
        orderRelated: false,
        orderId: tx.orderCode,
        transactionId: tx.txnId,
        time: tx.time,
        demo: true,
        detail: 'Giao dịch đã được ghi nhận trong Ví.'));
  }
  final completed = history
      .where((o) => o.status == OrderStatus.completed)
      .toList()
    ..sort((a, b) => b.time.compareTo(a.time));
  if (completed.isNotEmpty) {
    final order = completed.first;
    final messages = order.messages.where((m) => !m.fromMechanic).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    if (messages.isNotEmpty) {
      final m = messages.first;
      result.add(RevoNotification('Khách hàng gửi tin nhắn',
          '${order.customerName} vừa nhắn về đơn ${order.code}',
          id: 'demo-message-${order.code}',
          type: RevoNotificationType.message,
          orderRelated: true,
          orderId: order.code,
          time: m.time,
          demo: true,
          detail: m.isImage ? 'Khách đã gửi một hình ảnh.' : m.text));
    }
    if (order.customerRating != null) {
      result.add(RevoNotification(
          'Bạn nhận được đánh giá ${order.customerRating} sao',
          '${order.customerName} đánh giá đơn ${order.code}',
          id: 'demo-review-${order.code}',
          type: RevoNotificationType.review,
          orderRelated: true,
          orderId: order.code,
          time: order.time,
          demo: true,
          detail: order.customerReview));
    }
  }
  final verified =
      profile.documents.where((d) => d.status == VerificationStatus.verified);
  if (verified.isNotEmpty) {
    // Profile fixtures have no audit timestamp. This date is explicitly a
    // DEMO event timestamp, never asserted as a backend verification date.
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    result.add(RevoNotification('Giấy tờ đã được xác minh',
        '${verified.first.name} · Hồ sơ kỹ thuật viên của bạn đã được cập nhật',
        id: 'demo-verified-document',
        type: RevoNotificationType.certificate,
        orderRelated: false,
        time: DateTime(monday.year, monday.month, monday.day - 4, 14, 10),
        demo: true,
        isRead: true,
        detail: 'Xem trạng thái từng giấy tờ và chứng chỉ.'));
  }
  return result..sort((a, b) => b.time.compareTo(a.time));
}
