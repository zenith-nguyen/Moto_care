import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../data/demo_notifications.dart';
import '../config/app_config.dart';
import '../services/otp_service.dart';
import '../models/models.dart';
import '../models/payout_request.dart';
import '../utils/format.dart';

/// Trạng thái dùng chung toàn app (mock, lưu trong RAM).
/// Màn hình lắng nghe bằng `ListenableBuilder(listenable: appState, ...)`.
final AppState appState = AppState();

class AppState extends ChangeNotifier {
  AppState({bool? demoEnabled, OtpService? otpService})
      : demoEnabled = demoEnabled ?? AppConfig.demoEnabled {
    _otpService = this.demoEnabled
        ? (otpService ?? DemoOtpService())
        : UnconfiguredOtpService();
    if (this.demoEnabled) {
      notifications.addAll(demoNotifications(
          profile: profile,
          history: history,
          transactions: transactions,
          now: DateTime.now()));
    }
  }
  final bool demoEnabled;
  late final OtpService _otpService;
  bool sessionActive = true;
  void startDemoSession() {
    if (!demoEnabled) throw StateError('Dịch vụ đăng nhập chưa được cấu hình.');
    sessionActive = true;
    tabIndex = 0;
    isOnline = networkAvailable && gpsEnabled;
    notifyListeners();
  }

  bool signOut() {
    if (activeOrder != null) return false;
    sessionActive = false;
    isOnline = false;
    tabIndex = 0;
    notifyListeners();
    return true;
  }

  int get monthIncome {
    final now = DateTime.now();
    return transactions
        .where((tx) =>
            tx.isCredit &&
            tx.time.year == now.year &&
            tx.time.month == now.month)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  MechanicProfile profile = MockData.profile();
  final List<OrderHistoryItem> history = MockData.history();

  /// Presentation-only orders (never part of history, wallet or income).
  final List<OrderHistoryItem> showcaseOrders = MockData.showcaseOrders();
  bool showcaseOrdersEnabled = false;

  /// Only this one UI preference is persisted (a single boolean). Orders,
  /// history, wallet and the active order are still in-memory demo data.
  static const showcasePreferenceKey = 'revo.demo.showcase_orders';

  // Persistence only starts after restorePreferences() (i.e. in the real app),
  // so a default value can never overwrite what was saved, and tests do not
  // touch the plugin.
  bool _preferencesReady = false;

  void setShowcaseOrders(bool value) {
    if (!demoEnabled) return;
    showcaseOrdersEnabled = value;
    notifyListeners();
    if (_preferencesReady) _saveShowcasePreference(value);
  }

  /// Restores the saved switch before the first frame (called from `main`).
  /// With nothing saved, or on any read error, the safe default (off) stays.
  Future<void> restorePreferences() async {
    if (!demoEnabled) return;
    try {
      final saved = (await SharedPreferences.getInstance())
          .getBool(showcasePreferenceKey);
      if (saved != null && saved != showcaseOrdersEnabled) {
        showcaseOrdersEnabled = saved;
        notifyListeners();
      }
    } catch (_) {
      // Unreadable storage: keep the safe default (off).
    } finally {
      _preferencesReady = true;
    }
  }

  Future<void> _saveShowcasePreference(bool value) async {
    try {
      await (await SharedPreferences.getInstance())
          .setBool(showcasePreferenceKey, value);
    } catch (_) {}
  }

  final List<WalletTransaction> transactions = MockData.transactions();

  /// Demo fixtures only: no Admin sync exists, and these never move the balance.
  final List<PayoutRequest> payoutRequests = MockData.payoutRequests();

  bool isOnline = true;
  int tabIndex = 0;
  ActiveOrder? activeOrder;

  // ---------- Ví & thống kê ----------
  int balance = 1250000;
  int todayIncome = 1250000;
  int get weekIncome => dailyIncome.fold(0, (sum, amount) => sum + amount);
  int totalCompletedOrders = 124;
  int weekWithdrawn = 800000;
  int weekOrders = 8;
  final List<int> dailyIncome = MockData.dailyIncome();

  /// Thu nhập 7 ngày T2..CN.
  List<int> get last7Days => List.unmodifiable(dailyIncome);

  int get highestDayIncome => dailyIncome.reduce((a, b) => a > b ? a : b);

  int _offerSeq = 0;
  int _withdrawSeq = 33;
  final Map<ChatMessage, Timer> _deliveryTimers = {};
  final Map<String, Timer> _replyTimers = {};
  final Map<String, WalletTransaction> _withdrawRequests = {};
  bool networkAvailable = true;
  bool notificationsEnabled = true;
  bool gpsEnabled = true;
  final List<MechanicService> services = [
    MechanicService('Kích bình (12V, 24V)'),
    MechanicService('Thay lốp'),
    MechanicService('Cứu hộ ngập nước'),
    MechanicService('Sửa xe tại chỗ'),
    MechanicService('Kéo xe'),
    // Indices 5-6 are appended so the original five keep their positions.
    // Not registered by default and no demo offers/prices exist for them yet.
    MechanicService('Tiếp nhiên liệu', enabled: false, hasDemoOffers: false),
    MechanicService('Thay nhớt, bảo dưỡng',
        enabled: false, hasDemoOffers: false),
  ];
  final List<RevoNotification> notifications = [];
  int get unreadCount => notifications.where((n) => !n.read).length;
  void markNotificationRead(RevoNotification item) {
    item.read = true;
    notifyListeners();
  }

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void setNetworkAvailable(bool value) {
    networkAvailable = value;
    if (!value) isOnline = false;
    notifyListeners();
  }

  void setNotifications(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void setGps(bool value) {
    gpsEnabled = value;
    if (!value) isOnline = false;
    notifyListeners();
  }

  void saveServices(List<bool> values) {
    if (values.length != services.length || !values.contains(true)) {
      throw ArgumentError('Cần bật ít nhất một dịch vụ.');
    }
    for (var i = 0; i < services.length; i++) {
      services[i].enabled = values[i];
    }
    notifyListeners();
  }

  void _notify(String title, String body,
      {bool orderRelated = true,
      String? orderId,
      String? transactionId,
      RevoNotificationType? type,
      String? detail}) {
    notifications.insert(
        0,
        RevoNotification(title, body,
            orderRelated: orderRelated,
            orderId: orderId,
            transactionId: transactionId,
            type: type,
            detail: detail,
            demo: demoEnabled));
  }

  void setOnline(bool value) {
    isOnline = value && sessionActive && gpsEnabled && networkAvailable;
    notifyListeners();
  }

  void setTab(int index) {
    if (index < 0 || index > 3) throw RangeError.range(index, 0, 3);
    tabIndex = index;
    notifyListeners();
  }

  // ---------- Hồ sơ ----------
  void updateProfile({required String name, required String bio}) {
    if (name.trim().isNotEmpty) profile.name = name.trim();
    profile.bio = bio.trim();
    notifyListeners();
  }

  void saveProfessionalProfile(
      {required String name,
      required String bio,
      required String phone,
      required String email,
      required int experienceYears,
      required String specialty,
      required String area,
      required List<String> vehicles}) {
    if (name.trim().length < 2 || name.trim().length > 80) {
      throw const FormatException('Vui lòng nhập họ tên từ 2–80 ký tự.');
    }
    if (phone.isNotEmpty &&
        !RegExp(r'^(0\d{9}|\+84\d{9})$').hasMatch(phone.trim())) {
      throw const FormatException('Số điện thoại chưa hợp lệ.');
    }
    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      throw const FormatException('Email chưa hợp lệ.');
    }
    if (bio.length > 500 ||
        experienceYears < 0 ||
        experienceYears > 60 ||
        specialty.trim().isEmpty ||
        specialty.length > 80 ||
        area.trim().isEmpty ||
        vehicles.isEmpty ||
        vehicles.any((v) => !AppConfig.vehicleTypes.contains(v))) {
      throw const FormatException(
          'Vui lòng kiểm tra thông tin nghề nghiệp và khu vực.');
    }
    profile
      ..name = name.trim()
      ..bio = bio.trim()
      ..phone = phone.trim()
      ..email = email.trim()
      ..experienceYears = experienceYears
      ..specialty = specialty.trim()
      ..area = area.trim()
      ..supportedVehicles = List.unmodifiable(vehicles);
    notifyListeners();
  }

  void setArea(String area) {
    profile.area = area;
    notifyListeners();
  }

  /// Đăng ký kỹ năng mới -> luôn ở trạng thái chờ Admin xác minh.
  bool registerSkill(String name) {
    final value = name.trim();
    if (value.isEmpty || profile.skills.any((skill) => skill.name == value)) {
      return false;
    }
    profile.skills.add(Skill(name: value, status: VerificationStatus.pending));
    notifyListeners();
    return true;
  }

  // ---------- Đơn hàng ----------
  /// Số offer đã gửi tới thợ trong phiên demo hiện tại.
  int get offerSeq => _offerSeq;

  OrderOffer nextOffer({int? serviceIndex}) {
    if (!demoEnabled || !sessionActive) {
      throw StateError('Chưa có dịch vụ điều phối đơn ngoài chế độ demo.');
    }
    if (!isOnline || !networkAvailable || !gpsEnabled || activeOrder != null) {
      throw StateError('Chưa sẵn sàng nhận đơn mới.');
    }
    final available = List.generate(services.length, (i) => i)
        .where((i) => services[i].enabled && services[i].hasDemoOffers)
        .toList();
    if (available.isEmpty) throw StateError('Chưa bật dịch vụ cứu hộ.');
    if (serviceIndex != null && !services[serviceIndex].enabled) {
      throw StateError('Dịch vụ này đang tắt.');
    }
    if (serviceIndex != null && !available.contains(serviceIndex)) {
      throw StateError('Chưa có đơn mẫu cho dịch vụ này.');
    }
    final service = serviceIndex ?? available[_offerSeq % available.length];
    final base = MockData.offers[service == 1 ? 1 : 0];
    final seq = _offerSeq++;
    return OrderOffer(
      code: '#RVO${3281 + seq}',
      expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      issue: const [
        'Hết bình',
        'Xẹp lốp',
        'Ngập nước',
        'Chết máy',
        'Xe cần kéo'
      ][service],
      description: service < 2
          ? base.description
          : 'Xe gặp sự cố, cần hỗ trợ ${services[service].name.toLowerCase()}. Vui lòng liên hệ khi tới nơi.',
      vehicle: service == 4 ? 'Toyota Vios' : base.vehicle,
      plate: service == 4 ? '' : base.plate,
      customerName: base.customerName,
      customerPhone: base.customerPhone,
      customerEmail: base.customerEmail,
      customerRating: base.customerRating,
      customerRatingCount: base.customerRatingCount,
      customerVerified: base.customerVerified,
      address: base.address,
      distanceKm: base.distanceKm,
      etaMinutes: base.etaMinutes,
      price: const [150000, 120000, 350000, 100000, 500000][service],
      platformFee: base.platformFee,
    );
  }

  ActiveOrder _order(String orderId) {
    final order = activeOrder;
    if (order == null || order.orderId != orderId) {
      throw StateError('Đơn không còn hoạt động hoặc mã đơn không khớp.');
    }
    return order;
  }

  ActiveOrder acceptOffer(OrderOffer offer) {
    if (!demoEnabled || !sessionActive) {
      throw StateError('Phiên nhận đơn không khả dụng.');
    }
    if (activeOrder != null) {
      if (activeOrder!.orderId == offer.orderId) return activeOrder!;
      throw StateError(
          'Vui lòng hoàn thành đơn hiện tại trước khi nhận đơn mới.');
    }
    if (!isOnline || !networkAvailable || !gpsEnabled) {
      throw StateError('Cần trực tuyến, có mạng và bật định vị để nhận đơn.');
    }
    if (history.any((item) => item.orderId == offer.orderId) ||
        transactions
            .any((tx) => tx.isCredit && tx.orderCode == offer.orderId)) {
      throw StateError('Mã đơn này đã được xử lý.');
    }
    if (offer.expiresAt != null && !DateTime.now().isBefore(offer.expiresAt!)) {
      throw StateError('Đơn đã hết hạn.');
    }
    final now = DateTime.now();
    activeOrder = ActiveOrder(
      offer: offer,
      acceptedAt: now,
      messages: MockData.openingChat(now),
      quoteDraft: [
        for (final entry in MockData.quoteServices)
          QuoteLine(entry.$1, entry.$2)
      ],
    );
    _otpService.bind(offer);
    _notify('Đã nhận đơn cứu hộ', '${offer.issue} · ${offer.code}',
        orderId: offer.orderId);
    notifyListeners();
    return activeOrder!;
  }

  void beginNavigation({required String orderId}) {
    final o = _order(orderId);
    if (o.step == OrderStep.navigating) return;
    if (o.step != OrderStep.received || !networkAvailable || !gpsEnabled) {
      throw StateError('Không thể bắt đầu dẫn đường ở trạng thái hiện tại.');
    }
    o.navigationStartedAt = DateTime.now();
    o.step = OrderStep.navigating;
    notifyListeners();
  }

  void markArrived({required String orderId}) {
    final o = _order(orderId);
    if (o.step == OrderStep.arrived) return;
    if (o.step != OrderStep.navigating || o.navigationStartedAt == null) {
      throw StateError('Cần bắt đầu dẫn đường trước khi xác nhận đã đến.');
    }
    o.step = OrderStep.arrived;
    o.arrivedAt = DateTime.now();
    notifyListeners();
  }

  ActiveOrder _otpOrder(String orderId) {
    final o = _order(orderId);
    if (o.step != OrderStep.arrived ||
        o.arrivedAt == null ||
        o.navigationStartedAt == null) {
      throw StateError('Cần xác nhận đã đến trước khi nhập mã.');
    }
    return o;
  }

  String? demoCodeFor(String orderId) =>
      demoEnabled ? _otpService.demoCodeFor(orderId) : null;
  void _otpError(ActiveOrder o, String message) {
    o.otp.status = OtpActionState.error;
    o.otp.message = message;
    notifyListeners();
  }

  void _beginRepair(ActiveOrder o) {
    o.otp.status = OtpActionState.verified;
    o.otp.message = 'Xác nhận thành công';
    o.otpVerifiedAt = DateTime.now();
    o.repairStartedAt = o.otpVerifiedAt;
    o.step = OrderStep.repairing;
    notifyListeners();
  }

  /// Synchronous demo entry retained for fixtures; production cannot use a
  /// client-side cached code. UI uses the asynchronous verification below.
  bool startRepair({required String orderId, required String code}) {
    final o = _otpOrder(orderId);
    if (!demoEnabled) throw StateError('Dịch vụ xác nhận chưa được cấu hình.');
    if (o.otp.busy) return false;
    if (!RegExp(r'^\d{4}$').hasMatch(code) || demoCodeFor(orderId) != code) {
      return false;
    }
    _beginRepair(o);
    return true;
  }

  Future<bool> verifyOtp(
      {required String orderId, required String code}) async {
    final o = _otpOrder(orderId);
    if (o.otp.busy) return false;
    if (!RegExp(r'^\d{4}$').hasMatch(code)) {
      _otpError(o, 'Vui lòng nhập đủ 4 chữ số.');
      return false;
    }
    if (!networkAvailable) {
      _otpError(o, 'Mất kết nối mạng. Vui lòng thử lại.');
      return false;
    }
    o.otp.status = OtpActionState.verifying;
    o.otp.message = null;
    notifyListeners();
    try {
      final valid = await _otpService.verify(orderId, code);
      if (activeOrder != o || o.step != OrderStep.arrived) return false;
      if (!networkAvailable) {
        _otpError(o, 'Mất kết nối mạng. Vui lòng thử lại.');
        return false;
      }
      if (!valid) {
        _otpError(o, 'Mã không chính xác. Vui lòng kiểm tra lại với khách.');
        return false;
      }
      _beginRepair(o);
      return true;
    } catch (error) {
      if (activeOrder == o) {
        _otpError(
            o,
            error is StateError
                ? error.message
                : 'Không thể xác nhận mã. Vui lòng thử lại.');
      }
      return false;
    }
  }

  Future<bool> resendOtp(
      {required String orderId, required OtpChannel channel}) async {
    final o = _otpOrder(orderId);
    if (o.otp.busy) return false;
    if (o.otp.cooldownSeconds > 0) {
      _otpError(o, 'Vui lòng chờ ${o.otp.cooldownSeconds}s trước khi gửi lại.');
      return false;
    }
    if (!networkAvailable) {
      _otpError(o, 'Mất kết nối mạng. Vui lòng thử lại.');
      return false;
    }
    if (channel == OtpChannel.email &&
        (o.offer.customerEmail?.isEmpty ?? true)) {
      _otpError(o, 'Đơn này chưa có email của khách. Vui lòng chọn SMS.');
      return false;
    }
    o.otp.channel = channel;
    o.otp.status = OtpActionState.sending;
    o.otp.message = null;
    notifyListeners();
    try {
      await _otpService.resend(orderId, channel);
      if (activeOrder != o || o.step != OrderStep.arrived) return false;
      if (!networkAvailable) {
        _otpError(o, 'Mất kết nối mạng. Vui lòng thử lại.');
        return false;
      }
      o.otp.resendAvailableAt = DateTime.now().add(AppConfig.otpCooldown);
      o.otp.status = OtpActionState.sent;
      final label = channel == OtpChannel.sms ? 'SMS' : 'Email';
      final contact = channel == OtpChannel.sms
          ? maskPhone(o.offer.customerPhone)
          : maskEmail(o.offer.customerEmail);
      o.otp.message = 'Đã mô phỏng gửi mã qua $label đến $contact.';
      notifyListeners();
      return true;
    } catch (error) {
      if (activeOrder == o) {
        _otpError(
            o,
            error is StateError
                ? error.message
                : 'Không thể gửi mã. Vui lòng thử lại.');
      }
      return false;
    }
  }

  void advanceRepair({required String orderId}) {
    final o = _order(orderId);
    if (!o.canAdvanceRepair) {
      throw StateError(o.completionBlockedReason ?? 'Đã hoàn tất checklist.');
    }
    o.repairStage++;
    notifyListeners();
  }

  void setQuoteQuantity({
    required String orderId,
    required int index,
    required int quantity,
  }) {
    final o = _order(orderId);
    if (o.step != OrderStep.repairing || o.quoteStatus != QuoteStatus.none) {
      throw StateError('Báo giá chưa ở chế độ chỉnh sửa.');
    }
    if (index < 0 ||
        index >= o.quoteDraft.length ||
        quantity < 0 ||
        quantity > 9) {
      throw ArgumentError('Số lượng không hợp lệ.');
    }
    o.quoteDraft[index] = o.quoteDraft[index].withQuantity(quantity);
    notifyListeners();
  }

  /// Chỉ khách mô phỏng mới giải quyết báo giá; không tự duyệt bằng timer.
  void sendQuote({required String orderId}) {
    final o = _order(orderId);
    if (!networkAvailable ||
        o.step != OrderStep.repairing ||
        o.otpVerifiedAt == null ||
        o.quoteStatus != QuoteStatus.none ||
        o.draftExtra <= 0) {
      throw StateError('Báo giá chưa hợp lệ hoặc đang chờ phản hồi.');
    }
    o.submittedQuote = List.unmodifiable(
      o.quoteDraft.where((line) => line.quantity > 0),
    );
    o.proposedPrice = o.offer.price + o.draftExtra;
    o.quoteReason = o.submittedQuote
        .map((line) => '${line.name} × ${line.quantity}')
        .join(', ');
    o.quoteSentAt = DateTime.now();
    o.quoteTimeline.add(
      TimelineEvent(
        'Gửi báo giá: ${formatVnd(o.proposedPrice!)}',
        o.quoteSentAt!,
      ),
    );
    o.quoteResolvedAt = null;
    o.quoteStatus = QuoteStatus.pending;
    o.step = OrderStep.quoting;
    // New required work invalidates repair/handover checks from the old scope.
    // Keep inspection, but never mark proposed work as already performed.
    if (o.repairStage > 1) {
      o.repairStage = 1;
      o.quoteTimeline.add(
        TimelineEvent(
          'Cần kiểm tra lại sửa chữa và bàn giao sau báo giá mới',
          o.quoteSentAt!,
        ),
      );
    }
    notifyListeners();
  }

  void cancelQuote({required String orderId}) {
    final o = _order(orderId);
    if (o.otpVerifiedAt == null) throw StateError('Chưa bắt đầu sửa chữa.');
    if (o.quoteStatus == QuoteStatus.pending) {
      throw StateError('Cần chờ khách phản hồi trước khi lập lại báo giá.');
    }
    o.step = OrderStep.repairing;
    o.proposedPrice = null;
    o.quoteStatus = QuoteStatus.none;
    // Giữ nháp và khoản đã được duyệt trước đó khi lập lại báo giá.
    notifyListeners();
  }

  void resolveQuote(bool accepted, {required String orderId}) {
    if (!demoEnabled) throw StateError('Phản hồi khách cần backend.');
    final o = _order(orderId);
    if (o.quoteStatus != QuoteStatus.pending) return;
    o.quoteStatus = accepted ? QuoteStatus.accepted : QuoteStatus.rejected;
    o.rejectedQuoteNeedsAction = !accepted;
    o.quoteResolvedAt = DateTime.now();
    o.quoteTimeline.add(
      TimelineEvent(
        accepted ? 'Khách đã đồng ý báo giá' : 'Khách từ chối báo giá',
        o.quoteResolvedAt!,
      ),
    );
    o.step = OrderStep.repairing;
    if (accepted) {
      o.approvedExtra = o.proposedPrice! - o.offer.price;
      o.approvedQuote = List.unmodifiable(o.submittedQuote);
    }
    _notify(
      accepted ? 'Khách đã duyệt báo giá' : 'Khách từ chối báo giá',
      '${o.orderId} · ${o.offer.vehicle}',
      orderId: o.orderId,
      type: accepted
          ? RevoNotificationType.quoteApproved
          : RevoNotificationType.quoteRejected,
      detail: accepted
          ? 'Bạn có thể tiếp tục sửa chữa.'
          : 'Mở báo giá để xem phản hồi và xử lý tiếp.',
    );
    notifyListeners();
  }

  /// Explicitly omit rejected work; previously approved charges remain intact.
  void continueWithoutRejectedQuote({required String orderId}) {
    final o = _order(orderId);
    if (!o.rejectedQuoteNeedsAction ||
        (o.quoteStatus != QuoteStatus.rejected &&
            o.quoteStatus != QuoteStatus.none)) {
      throw StateError('Cần xử lý phản hồi từ chối trước khi tiếp tục.');
    }
    o.rejectedQuoteNeedsAction = false;
    o.quoteStatus = QuoteStatus.rejected;
    o.quoteTimeline.add(
      TimelineEvent(
        'Tiếp tục theo chi phí đã xác nhận; bỏ hạng mục bị từ chối',
        DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Hoàn thành đơn: ghi lịch sử, cộng tiền vào ví (đã trừ chiết khấu sàn), tăng tiến độ hạng.
  OrderHistoryItem completeOrder({required String orderId}) {
    final previous = history.where(
      (item) => item.orderId == orderId && item.status == OrderStatus.completed,
    );
    if (previous.isNotEmpty) return previous.first;
    final o = _order(orderId);
    final blocked = o.completionBlockedReason;
    if (blocked != null) throw StateError(blocked);
    final now = DateTime.now();
    final offer = o.offer;
    final accepted = o.approvedExtra > 0;
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
      extraReason: accepted
          ? o.approvedQuote
              .map((line) => '${line.name} × ${line.quantity}')
              .join(', ')
          : null,
      extraItems: o.approvedQuote,
      messages: o.messages,
      customerRating: 5,
      customerReview: 'Thợ tới nhanh, nhiệt tình, giá hợp lý!',
      timeline: [
        TimelineEvent('Đã nhận đơn', o.acceptedAt),
        TimelineEvent('Bắt đầu dẫn đường', o.navigationStartedAt!),
        if (o.arrivedAt != null) TimelineEvent('Đã đến nơi', o.arrivedAt!),
        if (o.repairStartedAt != null)
          TimelineEvent('Xác nhận mã và bắt đầu sửa', o.repairStartedAt!),
        ...o.quoteTimeline,
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
    totalCompletedOrders++;
    weekOrders += 1;
    dailyIncome[now.weekday - 1] += item.earning;
    profile.tierOrders += 1;
    o.step = OrderStep.completed;
    activeOrder = null;
    _notify(
        'Hoàn thành đơn hàng', '${offer.code} · +${formatVnd(item.earning)}',
        orderId: offer.orderId);
    final credited = transactions.first;
    _notify('Thu nhập đã cộng vào Ví',
        '+${formatVnd(credited.amount)} từ đơn ${offer.orderId}',
        orderRelated: false,
        orderId: offer.orderId,
        transactionId: credited.txnId,
        type: RevoNotificationType.income,
        detail: 'Số dư ví đã được cập nhật.');
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
  WalletTransaction? requestWithdraw(int amount, {required String requestId}) {
    if (!demoEnabled || !sessionActive) return null;
    final previous = _withdrawRequests[requestId];
    if (previous != null) return previous.amount == amount ? previous : null;
    if (!networkAvailable ||
        amount < 50000 ||
        amount > balance ||
        requestId.trim().isEmpty) {
      return null;
    }
    final transaction = WalletTransaction(
      code: '#RT${(_withdrawSeq++).toString().padLeft(4, '0')}',
      txnId: 'TX-${88300 + _withdrawSeq}',
      type: TxType.debit,
      amount: amount,
      time: DateTime.now(),
      withdrawStatus: WithdrawStatus.pending,
    );
    balance -= amount;
    weekWithdrawn += amount;
    transactions.insert(0, transaction);
    _withdrawRequests[requestId] = transaction;
    _notify('Đã nhận yêu cầu rút tiền', '${formatVnd(amount)} · Đang xử lý',
        orderRelated: false,
        transactionId: transaction.txnId,
        type: RevoNotificationType.withdrawal);
    notifyListeners();
    return transaction;
  }

  bool resolveWithdraw(String transactionId, {required bool approved}) {
    if (!demoEnabled) return false;
    final matches =
        transactions.where((tx) => tx.txnId == transactionId && !tx.isCredit);
    if (matches.isEmpty) return false;
    final tx = matches.first;
    if (tx.withdrawStatus != WithdrawStatus.pending) return false;
    tx.withdrawStatus =
        approved ? WithdrawStatus.approved : WithdrawStatus.failed;
    tx.resolvedAt = DateTime.now();
    if (!approved) {
      balance += tx.amount;
      weekWithdrawn -= tx.amount;
    }
    _notify(
        approved ? 'Rút tiền thành công' : 'Rút tiền thất bại',
        approved
            ? '${formatVnd(tx.amount)} · Kết quả mô phỏng'
            : '${formatVnd(tx.amount)} đã được hoàn lại vào ví.',
        orderRelated: false,
        transactionId: tx.txnId,
        type: RevoNotificationType.withdrawal);
    notifyListeners();
    return true;
  }

  ChatMessage sendChat(String orderId, {String? text, bool isImage = false}) {
    final o = _order(orderId);
    if (!isImage && (text?.trim().isEmpty ?? true)) {
      throw ArgumentError('Tin nhắn rỗng.');
    }
    final message = ChatMessage(
        fromMechanic: true,
        time: DateTime.now(),
        text: text?.trim(),
        isImage: isImage,
        imageVehicle: isImage ? o.offer.vehicle : null);
    o.messages.add(message);
    _deliverChat(o, message);
    return message;
  }

  void retryChat(String orderId, ChatMessage message) {
    final o = _order(orderId);
    if (!o.messages.contains(message) ||
        message.status != MessageStatus.failed) {
      return;
    }
    _deliverChat(o, message);
  }

  void _deliverChat(ActiveOrder o, ChatMessage message) {
    _deliveryTimers.remove(message)?.cancel();
    message.status =
        networkAvailable ? MessageStatus.sending : MessageStatus.failed;
    if (networkAvailable) {
      _deliveryTimers[message] = Timer(const Duration(milliseconds: 800), () {
        _deliveryTimers.remove(message);
        message.status =
            networkAvailable ? MessageStatus.sent : MessageStatus.failed;
        if (message.status == MessageStatus.sent && !o.demoReplyScheduled) {
          o.demoReplyScheduled = true;
          _replyTimers[o.orderId] =
              Timer(const Duration(milliseconds: 1500), () {
            _replyTimers.remove(o.orderId);
            if (networkAvailable) {
              o.messages.add(ChatMessage(
                  fromMechanic: false,
                  time: DateTime.now(),
                  text: 'Dạ em cảm ơn anh nhiều nha.'));
              _notify('Khách hàng gửi tin nhắn',
                  '${o.offer.customerName} vừa nhắn về đơn ${o.orderId}',
                  orderId: o.orderId,
                  type: RevoNotificationType.message,
                  detail: o.messages.last.text);
              notifyListeners();
            } else {
              o.demoReplyScheduled = false;
            }
          });
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _deliveryTimers.values) {
      timer.cancel();
    }
    for (final timer in _replyTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
