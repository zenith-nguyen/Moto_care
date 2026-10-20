import 'package:flutter/material.dart';
import '../models/models.dart';

/// Coarse grouping used only by the All services screen filters.
enum HomeServiceCategory { rescue, maintenance }

class HomeService {
  const HomeService(this.id, this.label, this.icon,
      {this.dispatchIndex,
      this.image,
      this.category,
      this.keywords = '',
      this.description = ''});
  final String id, label;
  final IconData icon;
  final int? dispatchIndex;
  final String? image;
  final HomeServiceCategory? category;

  /// Extra search terms (Vietnamese, accents optional) for the services search.
  final String keywords;
  final String description;
}

const homeServices = [
  HomeService('battery', 'Kích bình', Icons.battery_charging_full_rounded,
      dispatchIndex: 0,
      image: 'assets/images/home_battery_car.png',
      category: HomeServiceCategory.rescue,
      keywords: 'ắc quy bình điện kích nổ đề không nổ hết điện',
      description: 'Xe không đề được?'),
  HomeService('tire', 'Thay lốp', Icons.tire_repair_rounded,
      dispatchIndex: 1,
      image: 'assets/images/home_tire_suv.png',
      category: HomeServiceCategory.rescue,
      keywords: 'lốp vỏ bánh xe xẹp thủng vá bánh dự phòng',
      description: 'Lốp xẹp, thủng?'),
  HomeService('flood', 'Ngập nước', Icons.flood_rounded,
      dispatchIndex: 2,
      image: 'assets/images/home_service_flood.png',
      category: HomeServiceCategory.rescue,
      keywords: 'cứu hộ ngập nước mưa lụt chết máy',
      description: 'Xe bị chết máy?'),
  HomeService('tow', 'Kéo xe', Icons.local_shipping_rounded,
      dispatchIndex: 4,
      image: 'assets/images/home_service_tow.png',
      category: HomeServiceCategory.rescue,
      keywords: 'cẩu kéo xe cứu hộ xe tải sàn trượt',
      description: 'Xe hư, không di chuyển?'),
  HomeService('repair', 'Sửa xe', Icons.build_rounded,
      dispatchIndex: 3,
      image: 'assets/images/home_service_repair.png',
      category: HomeServiceCategory.rescue,
      keywords: 'sửa chữa tại chỗ động cơ máy sự cố',
      description: 'Sự cố trên đường?'),
  HomeService('fuel', 'Tiếp nhiên liệu', Icons.local_gas_station_rounded,
      dispatchIndex: 5,
      image: 'assets/images/home_service_fuel.jpg',
      category: HomeServiceCategory.rescue,
      keywords: 'xăng dầu đổ xăng hết xăng nhiên liệu',
      description: 'Xe hết nhiên liệu?'),
  HomeService('maintenance', 'Thay nhớt, bảo dưỡng', Icons.oil_barrel_rounded,
      dispatchIndex: 6,
      image: 'assets/images/home_service_maintenance.jpg',
      category: HomeServiceCategory.maintenance,
      keywords: 'nhớt dầu máy bảo dưỡng định kỳ lọc dầu chăm sóc xe',
      description: 'Đến lịch chăm sóc xe?'),
  HomeService('all', 'Tất cả', Icons.grid_view_outlined,
      description: 'Xem đầy đủ dịch vụ'),
];

/// Real services only (the `all` entry is just the catalog shortcut).
int get homeServiceCount => homeServices.where((s) => s.id != 'all').length;

/// Home presents these four entries (2x2); the full catalog/filter retains all services.
/// A getter (not a top-level final) so Hot Reload re-evaluates the selection.
List<HomeService> get popularHomeServices => List.unmodifiable(homeServices
    .where((s) => const ['battery', 'tire', 'repair', 'all'].contains(s.id)));

enum HomeRequestStatus {
  waiting,
  assignedElsewhere,
  expired,
  completed,
  cancelled,
  active
}

class HomeRequest {
  const HomeRequest(
      {required this.offer,
      required this.serviceId,
      required this.title,
      required this.image,
      required this.requestedAt,
      required this.availableUntil,
      this.status = HomeRequestStatus.waiting});
  final OrderOffer offer;
  final String serviceId, title, image;
  final DateTime requestedAt, availableUntil;
  final HomeRequestStatus status;
}

/// Explicitly separate the new visual-design fixtures from real dispatch.
/// Samples never enter the ledger until explicitly accepted and completed.
List<HomeRequest> demoHomeRequests(DateTime now) => [
      HomeRequest(
          serviceId: 'battery',
          title: 'Kích bình xe ô tô',
          image: 'assets/images/home_battery_car.png',
          requestedAt: now.subtract(const Duration(minutes: 12)),
          availableUntil: now.add(const Duration(minutes: 30)),
          offer: const OrderOffer(
              code: '#DEMO-H001',
              issue: 'Hết bình',
              description:
                  'Yêu cầu mẫu: xe không đề được, cần hỗ trợ kích bình.',
              vehicle: 'Toyota Vios',
              plate: '',
              customerName: 'Khách demo Minh Anh',
              customerPhone: '0900000001',
              address: 'Nguyễn Thị Minh Khai, Quận 1, TP.HCM',
              distanceKm: 1.2,
              etaMinutes: 5,
              price: 150000,
              platformFee: 0)),
      HomeRequest(
          serviceId: 'tow',
          title: 'Kéo xe ô tô',
          image: 'assets/images/home_service_tow.png',
          requestedAt: now.subtract(const Duration(minutes: 20)),
          availableUntil: now.add(const Duration(minutes: 30)),
          offer: const OrderOffer(
              code: '#DEMO-H003',
              issue: 'Xe không thể di chuyển',
              description: 'Yêu cầu mẫu: xe hư, cần xe cứu hộ đưa về tiệm.',
              vehicle: 'Toyota Fortuner',
              plate: '',
              customerName: 'Khách demo Minh Tuấn',
              customerPhone: '0900000003',
              address: '321 Lê Hồng Phong, Quận 10, TP.HCM',
              distanceKm: 3.6,
              etaMinutes: 12,
              price: 350000,
              platformFee: 0)),
      HomeRequest(
          serviceId: 'tire',
          title: 'Thay lốp xe ô tô',
          image: 'assets/images/home_tire_suv.png',
          requestedAt: now.subtract(const Duration(minutes: 18)),
          availableUntil: now.add(const Duration(minutes: 30)),
          offer: const OrderOffer(
              code: '#DEMO-H002',
              issue: 'Xẹp lốp',
              description: 'Yêu cầu mẫu: lốp xe bị xẹp, cần thay lốp dự phòng.',
              vehicle: 'Toyota Fortuner',
              plate: '',
              customerName: 'Khách demo Quốc Huy',
              customerPhone: '0900000002',
              address: 'Võ Văn Kiệt, Quận 1, TP.HCM',
              distanceKm: 2.8,
              etaMinutes: 10,
              price: 200000,
              platformFee: 0)),
    ];

String homeSearchKey(String input) {
  const groups = [
    'àáạảãâầấậẩẫăằắặẳẵ',
    'èéẹẻẽêềếệểễ',
    'ìíịỉĩ',
    'òóọỏõôồốộổỗơờớợởỡ',
    'ùúụủũưừứựửữ',
    'ỳýỵỷỹ',
    'đ'
  ];
  const letters = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
  var text = input.toLowerCase().trim();
  for (var i = 0; i < groups.length; i++) {
    text = text.replaceAll(RegExp('[${groups[i]}]'), letters[i]);
  }
  // Decomposed (NFD) input: drop leftover combining marks (U+0300–U+036F and
  // the Vietnamese horn U+031B), e.g. "e" + dot below. Only the search *copy*
  // is normalised; the text field keeps exactly what the user typed.
  return text
      .replaceAll(RegExp('[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}
