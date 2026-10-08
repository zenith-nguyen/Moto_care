import 'package:flutter/material.dart';

import '../models/models.dart';

/// Toàn bộ dữ liệu mẫu của app (không gọi API).
class MockData {
  MockData._();

  /// Mock trạng thái thời tiết: set cứng = true để demo banner cảnh báo mưa.
  static const bool isRainIncoming = true;

  /// Bán kính hoạt động (km) hiển thị trên bản đồ Trang chủ.
  static const double activeRadiusKm = 5;

  static const String weekRange = '30/09 – 06/10/2026';
  static const int weekIncome = 1850000;
  static const int weekOrders = 12;
  static const double weekAvgRating = 4.9;

  static const List<String> districts = [
    'Quận 1',
    'Quận 3',
    'Quận 5',
    'Quận 10',
    'Quận 11',
    'Bình Thạnh',
    'Phú Nhuận',
    'Tân Bình',
  ];

  static MechanicProfile profile() => MechanicProfile(
    displayName: 'Minh Phát Garage',
    ownerName: 'Nguyễn Minh Phát',
    phone: '0908 123 456',
    verified: true,
    rating: 4.9,
    totalOrders: 44, // Hạng Bạc (20–49), còn 6 đơn lên Vàng (50)
    area: 'Quận 5',
  );

  static const List<OrderRequest> _templates = [
    OrderRequest(
      id: '#MC105',
      issue: 'Vá lốp không ruột',
      vehicle: 'Honda Vario 150',
      address: '273 An Dương Vương, Q.5',
      distanceKm: 1.2,
      earning: 60000,
      platformFee: 6000,
      customerName: 'Trần Quốc Bảo',
      customerPhone: '0901 234 567',
      etaMinutes: 6,
    ),
    OrderRequest(
      id: '#MC106',
      issue: 'Hết bình, cần kích bình',
      vehicle: 'Yamaha Exciter 155',
      address: '56 Nguyễn Trãi, Q.5',
      distanceKm: 2.4,
      earning: 150000,
      platformFee: 15000,
      customerName: 'Lê Thị Hạnh',
      customerPhone: '0912 345 678',
      etaMinutes: 10,
    ),
    OrderRequest(
      id: '#MC107',
      issue: 'Chết máy, cần cẩu kéo',
      vehicle: 'Honda SH 150i',
      address: '120 Hùng Vương, Q.10',
      distanceKm: 3.8,
      earning: 280000,
      platformFee: 28000,
      customerName: 'Phạm Đức Anh',
      customerPhone: '0987 654 321',
      etaMinutes: 14,
    ),
    OrderRequest(
      id: '#MC108',
      issue: 'Đứt dây ga',
      vehicle: 'Honda Wave Alpha',
      address: '18 Trần Hưng Đạo, Q.5',
      distanceKm: 4.5,
      earning: 90000,
      platformFee: 9000,
      customerName: 'Võ Thanh Tùng',
      customerPhone: '0933 111 222',
      etaMinutes: 16,
    ),
  ];

  /// 3 đơn khẩn cấp hiển thị ở ListView ngang trên Trang chủ.
  static List<OrderRequest> nearbyOrders() => _templates.take(3).toList();

  /// Đơn mới cho nút "Giả lập nổ đơn" (đổi mã đơn theo số thứ tự).
  static OrderRequest incomingOrder(int seq) {
    final t = _templates[seq % _templates.length];
    return t.withId('#MC${110 + seq}');
  }

  /// Lịch sử giao dịch (mới nhất trước). Thời gian tính theo ngày hiện tại
  /// để luôn hiển thị "Hôm nay"/"Hôm qua" đúng khi demo.
  static List<WalletTransaction> transactions() {
    final now = DateTime.now();
    DateTime at(int daysAgo, int h, int m) =>
        DateTime(now.year, now.month, now.day - daysAgo, h, m);

    return [
      WalletTransaction(orderId: '#MC104', time: at(0, 16, 42), amount: 95000),
      WalletTransaction(orderId: '#MC104', time: at(0, 16, 42), amount: -9500),
      WalletTransaction(orderId: '#MC103', time: at(0, 15, 10), amount: 150000),
      WalletTransaction(orderId: '#MC103', time: at(0, 15, 10), amount: -15000),
      WalletTransaction(orderId: '#MC102', time: at(0, 11, 25), amount: 60000),
      WalletTransaction(orderId: '#MC102', time: at(0, 11, 25), amount: -6000),
      WalletTransaction(orderId: '#MC101', time: at(0, 9, 48), amount: 45000),
      WalletTransaction(orderId: '#MC101', time: at(0, 9, 48), amount: -4500),
      WalletTransaction(orderId: '#MC100', time: at(1, 20, 15), amount: 180000),
      WalletTransaction(orderId: '#MC100', time: at(1, 20, 15), amount: -18000),
      WalletTransaction(orderId: '#MC099', time: at(1, 17, 5), amount: 120000),
      WalletTransaction(orderId: '#MC099', time: at(1, 17, 5), amount: -12000),
      WalletTransaction(orderId: '#MC098', time: at(2, 19, 30), amount: 210000),
      WalletTransaction(orderId: '#MC098', time: at(2, 19, 30), amount: -21000),
    ];
  }

  static List<ServiceSkill> services() => [
    ServiceSkill(
      name: 'Vá xe',
      description: 'Vá lốp, thay săm, bơm hơi',
      icon: Icons.tire_repair_outlined,
    ),
    ServiceSkill(
      name: 'Kích bình',
      description: 'Kích nổ máy khi hết bình ắc quy',
      icon: Icons.bolt_outlined,
    ),
    ServiceSkill(
      name: 'Cẩu kéo',
      description: 'Kéo xe về tiệm khi hư nặng',
      icon: Icons.local_shipping_outlined,
      enabled: false,
    ),
    ServiceSkill(
      name: 'Thay nhớt',
      description: 'Thay nhớt tại chỗ',
      icon: Icons.oil_barrel_outlined,
    ),
    ServiceSkill(
      name: 'Tiếp xăng khẩn cấp',
      description: 'Mang xăng đến khi xe hết xăng',
      icon: Icons.local_gas_station_outlined,
    ),
    ServiceSkill(
      name: 'Sửa điện',
      description: 'Đèn, còi, hệ thống đánh lửa',
      icon: Icons.electrical_services_outlined,
    ),
  ];
}
