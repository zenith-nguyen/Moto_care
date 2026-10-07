import '../../activity/models/rescue_order.dart';

class ServicePackage {
  const ServicePackage(this.id, this.name, this.price, this.serviceType);
  final String id;
  final String name;
  final int price;
  final RescueServiceType serviceType;

  RescueOrderItem item(int quantity) => RescueOrderItem(
    packageId: id,
    name: name,
    unitPrice: price,
    quantity: quantity,
    serviceType: serviceType,
  );
}

abstract final class MarketplaceCatalog {
  static const packages = [
    ServicePackage(
      'tire-tubed',
      'Vá lốp có ruột',
      30000,
      RescueServiceType.flatTire,
    ),
    ServicePackage(
      'tire-tubeless',
      'Vá lốp không ruột',
      50000,
      RescueServiceType.flatTire,
    ),
    ServicePackage(
      'tire-replace',
      'Thay ruột chính hãng',
      90000,
      RescueServiceType.flatTire,
    ),
    ServicePackage(
      'battery-jump',
      'Kích bình ắc quy',
      40000,
      RescueServiceType.batteryJump,
    ),
    ServicePackage(
      'battery-replace',
      'Thay bình mới GS/Globe',
      280000,
      RescueServiceType.batteryJump,
    ),
    ServicePackage(
      'fuel-2',
      'Giao 2 Lít A95',
      45000,
      RescueServiceType.outOfFuel,
    ),
    ServicePackage(
      'fuel-4',
      'Giao 4 Lít A95',
      85000,
      RescueServiceType.outOfFuel,
    ),
    ServicePackage(
      'flood-check',
      'Kiểm tra động cơ ngập nước',
      60000,
      RescueServiceType.floodedEngine,
    ),
    ServicePackage(
      'flood-repair',
      'Xử lý động cơ ngập nước',
      120000,
      RescueServiceType.floodedEngine,
    ),
    ServicePackage(
      'towing',
      'Cẩu kéo xe máy đến tiệm',
      150000,
      RescueServiceType.towing,
    ),
    ServicePackage(
      'maintenance',
      'Kiểm tra và bảo dưỡng cơ bản',
      100000,
      RescueServiceType.maintenance,
    ),
    ServicePackage(
      'charging',
      'Sạc xe điện và kiểm tra pin',
      50000,
      RescueServiceType.charging,
    ),
    ServicePackage(
      'engine',
      'Kiểm tra và cứu hộ chết máy',
      50000,
      RescueServiceType.engineFailure,
    ),
    ServicePackage(
      'night',
      'Cứu hộ đêm tận nơi',
      80000,
      RescueServiceType.nightRescue,
    ),
  ];

  static RescueServiceType? typeFor(String label) =>
      switch (label.replaceAll('\n', ' ').trim()) {
        'Vá xe' || 'Vá xe / Săm' || 'Xẹp lốp' => RescueServiceType.flatTire,
        'Kích bình' || 'Kích bình điện' => RescueServiceType.batteryJump,
        'Hết xăng' || 'Cứu hộ Hết xăng' => RescueServiceType.outOfFuel,
        'Sửa ngập nước' => RescueServiceType.floodedEngine,
        'Xe cẩu kéo' => RescueServiceType.towing,
        'Đặt lịch bảo dưỡng' => RescueServiceType.maintenance,
        'Trạm sạc' || 'Trạm sạc gần nhất' => RescueServiceType.charging,
        'Chết máy' => RescueServiceType.engineFailure,
        'Cứu hộ đêm 24/7' => RescueServiceType.nightRescue,
        _ => null,
      };
}
