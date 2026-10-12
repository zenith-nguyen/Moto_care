import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../utils/format.dart';

/// Trạng thái dùng chung toàn app (mock, lưu trong RAM).
/// Màn hình lắng nghe bằng `ListenableBuilder(listenable: appState, ...)`.
final AppState appState = AppState();

class AppState extends ChangeNotifier {
  MechanicProfile profile = MockData.profile();
  final List<OrderHistoryItem> history = MockData.history();
  final List<WalletTransaction> transactions = MockData.transactions();

  bool isOnline = true;
  int tabIndex = 0;
  ActiveOrder? activeOrder;

  /// "Lần đăng nhập sau tự vào giao diện Thợ" (công tắc trong sheet đã duyệt hồ sơ).
  bool autoOpenMechanic = true;

  // ---------- Ví & thống kê ----------
  int balance = 4250000;
  int todayIncome = 185000;
  int weekIncome = 1850000;
  int weekWithdrawn = 800000;
  int weekOrders = 12;
  final List<int> dailyIncome = MockData.dailyIncome();

  /// Thu nhập 7 ngày T2..CN.
  List<int> get last7Days => List.unmodifiable(dailyIncome);

  int get highestDayIncome => dailyIncome.reduce((a, b) => a > b ? a : b);

  int _offerSeq = 0;
  int _withdrawSeq = 33;
  Timer? _quoteTimer;

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  void setTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  void setAutoOpenMechanic(bool value) {
    autoOpenMechanic = value;
    notifyListeners();
  }

  // ---------- Hồ sơ ----------
  void updateProfile({required String name, required String bio}) {
    if (name.trim().isNotEmpty) profile.name = name.trim();
    profile.bio = bio.trim();
    notifyListeners();
  }

  void setArea(String area) {
    profile.area = area;
    notifyListeners();
  }

  /// Đăng ký kỹ năng mới -> luôn ở trạng thái chờ Admin xác minh.
  void registerSkill(String name) {
    profile.skills.add(Skill(name: name, status: VerificationStatus.pending));
    notifyListeners();
  }

  void logout() {
    _quoteTimer?.cancel();
    activeOrder = null;
    tabIndex = 0;
    isOnline = true;
    notifyListeners();
  }

  // ---------- Đơn hàng ----------
  /// Số offer đã gửi tới thợ (dùng để mock tình huống mất kết nối ở offer thứ hai).
  int get offerSeq => _offerSeq;

  OrderOffer nextOffer() {
    final base = MockData.offers[_offerSeq % MockData.offers.length];
    final seq = _offerSeq++;
    if (seq < MockData.offers.length) return base;
    return OrderOffer(
      code: '#MC${2341 + seq}',
      issue: base.issue,
      description: base.description,
      vehicle: base.vehicle,
      plate: base.plate,
      customerName: base.customerName,
      customerPhone: base.customerPhone,
      address: base.address,
      distanceKm: base.distanceKm,
      etaMinutes: base.etaMinutes,
      price: base.price,
      platformFee: base.platformFee,
    );
  }

  ActiveOrder acceptOffer(OrderOffer offer) {
    final now = DateTime.now();
    activeOrder = ActiveOrder(
      offer: offer,
      acceptedAt: now,
      messages: MockData.openingChat(now),
    );
    notifyListeners();
    return activeOrder!;
  }

  void markArrived() {
    final o = activeOrder;
    if (o == null) return;
    o.step = OrderStep.arrived;
    o.arrivedAt = DateTime.now();
    notifyListeners();
  }

  void startRepair() {
    final o = activeOrder;
    if (o == null) return;
    o.step = OrderStep.repairing;
    o.repairStartedAt = DateTime.now();
    notifyListeners();
  }

  /// Gửi đề xuất giá cuối. Mock: khách tự đồng ý sau 8 giây.
  void sendQuote(int price, String reason) {
    final o = activeOrder;
    if (o == null) return;
    o
      ..step = OrderStep.quoting
      ..proposedPrice = price
      ..quoteReason = reason
      ..quoteSentAt = DateTime.now()
      ..quoteStatus = QuoteStatus.pending;
    _quoteTimer?.cancel();
    _quoteTimer = Timer(const Duration(seconds: 8), () {
      if (activeOrder != o || o.quoteStatus != QuoteStatus.pending) return;
      o.quoteStatus = QuoteStatus.accepted;
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelQuote() {
    final o = activeOrder;
    if (o == null) return;
    _quoteTimer?.cancel();
    o
      ..step = OrderStep.repairing
      ..proposedPrice = null
      ..quoteReason = null
      ..quoteSentAt = null
      ..quoteStatus = QuoteStatus.none;
    notifyListeners();
  }

  /// Hoàn thành đơn: ghi lịch sử, cộng tiền vào ví (đã trừ chiết khấu sàn), tăng tiến độ hạng.
  OrderHistoryItem completeOrder() {
    final o = activeOrder!;
    _quoteTimer?.cancel();
    final now = DateTime.now();
    final offer = o.offer;
    final accepted = o.quoteStatus == QuoteStatus.accepted;
    final extra = o.finalPrice - offer.price;
    final item = OrderHistoryItem(
      code: offer.code,
      issue: offer.issue,
      vehicle: offer.vehicle,
      plate: offer.plate,
      customerName: offer.customerName,
      customerPhone: offer.customerPhone,
      address: offer.address,
      status: OrderStatus.completed,
      time: now,
      initialPrice: offer.price,
      finalPrice: o.finalPrice,
      fee: o.finalFee,
      extraReason: accepted ? o.quoteReason : null,
      messages: o.messages,
      customerRating: 5,
      customerReview: 'Thợ tới nhanh, nhiệt tình, giá hợp lý!',
      timeline: [
        TimelineEvent('Đã nhận đơn', o.acceptedAt),
        if (o.arrivedAt != null) TimelineEvent('Đã đến nơi', o.arrivedAt!),
        if (o.repairStartedAt != null) TimelineEvent('Bắt đầu sửa', o.repairStartedAt!),
        if (o.quoteSentAt != null && accepted)
          TimelineEvent('Báo giá cuối: +${formatVnd(extra)}', o.quoteSentAt!),
        TimelineEvent('Hoàn thành', now),
      ],
    );
    history.insert(0, item);
    transactions.insert(
      0,
      WalletTransaction(
        code: offer.code,
        txnId: 'TX-${88213 + history.length}',
        type: TxType.credit,
        amount: item.earning,
        time: now,
        orderCode: offer.code,
        serviceName: offer.issue,
        customerName: offer.customerName,
        customerPhone: offer.customerPhone,
        finalPrice: item.finalPrice,
        platformFee: item.fee,
      ),
    );
    balance += item.earning;
    todayIncome += item.earning;
    weekIncome += item.earning;
    weekOrders += 1;
    dailyIncome[now.weekday - 1] += item.earning;
    profile.tierOrders += 1;
    activeOrder = null;
    notifyListeners();
    return item;
  }

  void rateCustomer(OrderHistoryItem item, int stars, String comment) {
    item
      ..rating = stars
      ..ratingComment = comment.trim().isEmpty ? null : comment.trim();
    notifyListeners();
  }

  // ---------- Ví ----------
  /// Sandbox: ghi nhận yêu cầu rút, trừ ngay khỏi số dư và chờ Admin duyệt.
  bool requestWithdraw(int amount) {
    if (amount <= 0 || amount > balance) return false;
    balance -= amount;
    transactions.insert(
      0,
      WalletTransaction(
        code: '#RT${(_withdrawSeq++).toString().padLeft(4, '0')}',
        txnId: 'TX-${88300 + _withdrawSeq}',
        type: TxType.debit,
        amount: amount,
        time: DateTime.now(),
        withdrawStatus: WithdrawStatus.pending,
      ),
    );
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }
}
