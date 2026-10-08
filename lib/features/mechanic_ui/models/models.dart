import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 4 cấp hạng thợ (gamification): Đồng -> Bạc -> Vàng -> Kim Cương.
enum MechanicTier { bronze, silver, gold, diamond }

/// Thông tin hiển thị + ngưỡng số đơn của từng hạng.
class TierInfo {
  const TierInfo._(this.tier, this.name, this.color, this.minOrders);

  final MechanicTier tier;
  final String name; // "Bạc"
  final Color color; // màu icon huy chương
  final int minOrders; // số đơn tối thiểu để vào hạng này

  String get title => 'Hạng $name';

  static const TierInfo bronze = TierInfo._(
    MechanicTier.bronze,
    'Đồng',
    Color(0xFFB87333),
    0,
  );
  static const TierInfo silver = TierInfo._(
    MechanicTier.silver,
    'Bạc',
    Color(0xFF8E99A8),
    20,
  );
  static const TierInfo gold = TierInfo._(
    MechanicTier.gold,
    'Vàng',
    Color(0xFFE5A100),
    50,
  );
  static const TierInfo diamond = TierInfo._(
    MechanicTier.diamond,
    'Kim Cương',
    Color(0xFF7C3AED),
    100,
  );

  static const List<TierInfo> all = [bronze, silver, gold, diamond];

  static TierInfo of(MechanicTier tier) => all[tier.index];

  /// Hạng tương ứng với tổng số đơn đã hoàn thành.
  static TierInfo forOrders(int orders) {
    var result = bronze;
    for (final t in all) {
      if (orders >= t.minOrders) result = t;
    }
    return result;
  }

  TierInfo? get next =>
      tier.index + 1 < all.length ? all[tier.index + 1] : null;

  /// Số đơn còn thiếu để lên hạng kế tiếp (0 nếu đã max).
  int ordersToNext(int totalOrders) {
    final n = next;
    if (n == null) return 0;
    return math.max(0, n.minOrders - totalOrders);
  }

  /// Tiến độ 0..1 trong hạng hiện tại.
  double progress(int totalOrders) {
    final n = next;
    if (n == null) return 1;
    final span = n.minOrders - minOrders;
    return ((totalOrders - minOrders) / span).clamp(0.0, 1.0).toDouble();
  }
}

class MechanicProfile {
  MechanicProfile({
    required this.displayName,
    required this.ownerName,
    required this.phone,
    required this.verified,
    required this.rating,
    required this.totalOrders,
    required this.area,
  });

  String displayName; // tên tiệm / thợ
  final String ownerName;
  final String phone;
  final bool verified;
  final double rating;
  int totalOrders; // tổng số đơn đã hoàn thành (quyết định hạng)
  String area; // quận/huyện nhận đơn mặc định

  String get initial {
    final s = displayName.trim();
    return s.isEmpty ? '?' : s.substring(0, 1).toUpperCase();
  }

  TierInfo get tier => TierInfo.forOrders(totalOrders);
}

class OrderRequest {
  const OrderRequest({
    required this.id,
    required this.issue,
    required this.vehicle,
    required this.address,
    required this.distanceKm,
    required this.earning,
    required this.platformFee,
    required this.customerName,
    required this.customerPhone,
    required this.etaMinutes,
  });

  final String id; // "#MC105"
  final String issue; // "Vá lốp không ruột"
  final String vehicle; // "Honda Vario 150"
  final String address;
  final double distanceKm;
  final int earning; // thu nhập thợ nhận
  final int platformFee; // chiết khấu sàn
  final String customerName;
  final String customerPhone;
  final int etaMinutes;

  String get headline => '$issue — $vehicle';

  OrderRequest withId(String newId) => OrderRequest(
    id: newId,
    issue: issue,
    vehicle: vehicle,
    address: address,
    distanceKm: distanceKm,
    earning: earning,
    platformFee: platformFee,
    customerName: customerName,
    customerPhone: customerPhone,
    etaMinutes: etaMinutes,
  );
}

/// Trạng thái báo giá phát sinh: thợ gửi -> khách xác nhận trên app.
enum ExtraStatus { pending, confirmed }

/// Chế độ nhận đơn: tự động (đơn nổ thẳng lên màn hình) hoặc tự chọn từ danh sách.
enum OrderMode { auto, manual }

/// Chi phí phụ tùng phát sinh thợ báo thêm trong lúc sửa (vd: thay ruột xe / săm mới).
class ExtraItem {
  ExtraItem({
    required this.description,
    required this.amount,
    this.status = ExtraStatus.pending,
  });
  final String description;
  final int amount;
  ExtraStatus status;
}

class WalletTransaction {
  WalletTransaction({
    required this.orderId,
    required this.time,
    required this.amount,
  });

  final String orderId; // "#MC104"
  final DateTime time;
  final int amount; // > 0: cộng tiền từ đơn, < 0: trừ chiết khấu sàn

  bool get isIncome => amount > 0;
  String get label => isIncome ? 'Cộng tiền từ đơn hàng' : 'Trừ chiết khấu sàn';
}

class ServiceSkill {
  ServiceSkill({
    required this.name,
    required this.description,
    required this.icon,
    this.enabled = true,
  });

  final String name;
  final String description;
  final IconData icon;
  bool enabled;
}
