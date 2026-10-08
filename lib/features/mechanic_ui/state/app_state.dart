import 'package:flutter/widgets.dart';

import '../data/mock_data.dart';
import '../models/models.dart';

enum PartnerStatus { none, pending, approved }

enum AppMode { customer, mechanic }

/// Trạng thái dùng chung toàn app (mock, lưu trong RAM).
class AppState extends ChangeNotifier {
  final MechanicProfile profile = MockData.profile();
  final List<OrderRequest> nearbyOrders = MockData.nearbyOrders();
  final List<WalletTransaction> transactions = MockData.transactions();
  final List<ServiceSkill> services = MockData.services();

  bool isOnline = true;
  bool isRainIncoming = MockData.isRainIncoming;
  int tabIndex = 0;
  OrderMode orderMode = OrderMode.manual;

  // ---------- Đối tác: đăng ký -> Admin duyệt -> chuyển giao diện Thợ ----------
  PartnerStatus partnerStatus = PartnerStatus.none;
  AppMode mode = AppMode.customer;
  bool autoOpenMechanic = false; // lần đăng nhập sau tự vào giao diện Thợ

  /// Khách gửi hồ sơ qua mục "Trở thành đối tác" -> chờ duyệt trên CMS/Admin.
  void submitPartnerApplication(String shopName, String area) {
    profile.displayName = shopName.trim().isEmpty
        ? profile.displayName
        : shopName.trim();
    profile.area = area;
    partnerStatus = PartnerStatus.pending;
    notifyListeners();
  }

  /// Mock: Admin Backend bấm "Duyệt" (demo, không có backend thật).
  void approvePartnerDemo() {
    partnerStatus = PartnerStatus.approved;
    notifyListeners();
  }

  void switchMode(AppMode newMode) {
    mode = newMode;
    tabIndex = 0;
    if (newMode == AppMode.customer) isOnline = false;
    notifyListeners();
  }

  void setAutoOpenMechanic(bool value) {
    autoOpenMechanic = value;
    notifyListeners();
  }

  /// Bỏ qua đăng ký, vào thẳng giao diện Thợ (để demo nhanh).
  void skipToMechanic() {
    partnerStatus = PartnerStatus.approved;
    mode = AppMode.mechanic;
    tabIndex = 0;
    isOnline = true;
    notifyListeners();
  }

  void setOrderMode(OrderMode value) {
    orderMode = value;
    notifyListeners();
  }

  int balance = 1240000;
  int depositForDiscount = 500000;
  int todayRevenue = 350000;
  int todayOrders = 4;

  int _incomingSeq = 0;

  // ---------- Trang chủ ----------
  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }

  void setRain(bool value) {
    isRainIncoming = value;
    notifyListeners();
  }

  void setTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  /// Đơn "nổ" mới cho nút giả lập.
  OrderRequest nextIncomingOrder() => MockData.incomingOrder(_incomingSeq++);

  void removeNearby(OrderRequest order) {
    nearbyOrders.removeWhere((o) => o.id == order.id);
    notifyListeners();
  }

  /// Demo hạng thợ: bấm giữ vào card hạng để đổi sang hạng kế tiếp.
  void cycleTierDemo() {
    final next = (profile.tier.tier.index + 1) % TierInfo.all.length;
    final isLast = next == TierInfo.all.length - 1;
    profile.totalOrders = isLast
        ? TierInfo.all[next].minOrders + 20
        : TierInfo.all[next + 1].minOrders - 6;
    notifyListeners();
  }

  // ---------- Hồ sơ ----------
  void updateDisplayName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    profile.displayName = trimmed;
    notifyListeners();
  }

  void setArea(String area) {
    profile.area = area;
    notifyListeners();
  }

  void setService(ServiceSkill skill, bool enabled) {
    skill.enabled = enabled;
    notifyListeners();
  }

  // ---------- Ví ----------
  void deposit(int amount) {
    balance += amount;
    depositForDiscount += amount;
    notifyListeners();
  }

  bool withdraw(int amount) {
    if (amount <= 0 || amount > balance) return false;
    balance -= amount;
    notifyListeners();
    return true;
  }

  // ---------- Hoàn thành đơn ----------
  /// Cộng thu nhập (kèm phụ tùng phát sinh), trừ chiết khấu sàn, tăng số đơn
  /// (có thể lên hạng) và ghi 2 dòng vào lịch sử giao dịch.
  void completeOrder(OrderRequest order, int extraTotal) {
    final income = order.earning + extraTotal;
    final now = DateTime.now();
    transactions.insert(
      0,
      WalletTransaction(
        orderId: order.id,
        time: now,
        amount: -order.platformFee,
      ),
    );
    transactions.insert(
      0,
      WalletTransaction(orderId: order.id, time: now, amount: income),
    );
    balance += income - order.platformFee;
    todayRevenue += income;
    todayOrders += 1;
    profile.totalOrders += 1;
    notifyListeners();
  }
}

/// Cung cấp AppState cho toàn cây widget (đặt phía trên MaterialApp).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  /// Dùng trong build(): tự rebuild khi state đổi.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'Không tìm thấy AppScope trong cây widget');
    return scope!.notifier!;
  }

  /// Dùng trong callback (onTap...): không đăng ký rebuild.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'Không tìm thấy AppScope trong cây widget');
    return scope!.notifier!;
  }
}
