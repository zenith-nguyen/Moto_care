import '../../activity/models/rescue_order.dart';

typedef RescueOption = ({String label, int price});

({RescueServiceType type, List<RescueOption> options}) configurationFor(
  String serviceName,
) {
  final name = serviceName.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  final type = switch (name) {
    'vá xe' ||
    'vá xe / săm' ||
    'vá xe/săm' ||
    'xẹp lốp' => RescueServiceType.flatTire,
    'kích bình điện' || 'kích bình ắc quy' => RescueServiceType.batteryJump,
    'cứu hộ hết xăng' || 'hết xăng' => RescueServiceType.outOfFuel,
    'sửa ngập nước' || 'sửa xe ngập nước' => RescueServiceType.floodedEngine,
    'xe cẩu kéo' => RescueServiceType.towing,
    'đặt lịch bảo dưỡng' => RescueServiceType.maintenance,
    'trạm sạc gần nhất' || 'trạm sạc' => RescueServiceType.charging,
    'cứu hộ đêm 24/7' => RescueServiceType.nightRescue,
    _ => RescueServiceType.engineFailure,
  };
  final List<RescueOption> options = switch (type) {
    RescueServiceType.batteryJump => const [
      (label: 'Kích bình ắc quy (40k)', price: 40000),
      (label: 'Thay bình ắc quy mới (280k)', price: 280000),
    ],
    RescueServiceType.outOfFuel => const [
      (label: 'Giao 2 Lít A95 (45k)', price: 45000),
      (label: 'Giao 4 Lít A95 (85k)', price: 85000),
    ],
    RescueServiceType.floodedEngine => const [
      (label: 'Sấy bugi & Xả xăng con (60k)', price: 60000),
      (label: 'Thay nhớt ngập nước (120k)', price: 120000),
    ],
    RescueServiceType.flatTire => const [
      (label: 'Vá lốp có ruột (30k)', price: 30000),
      (label: 'Vá lốp không ruột (50k)', price: 50000),
      (label: 'Thay ruột mới (90k)', price: 90000),
    ],
    _ => const [(label: 'Kiểm tra & Cứu hộ tận nơi (50k)', price: 50000)],
  };
  return (type: type, options: options);
}

const rescueVehicleTypes = ['Xe tay ga', 'Xe số', 'Xe côn tay / PKL'];
final incidentServiceTypes = List<RescueServiceType>.unmodifiable(
  RescueServiceType.values.where(
    (type) =>
        type != RescueServiceType.maintenance &&
        type != RescueServiceType.charging,
  ),
);
