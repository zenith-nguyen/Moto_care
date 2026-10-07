import 'rescue_order.dart';

enum ActivityFilter {
  all('Tất cả'),
  sos('Cứu hộ SOS'),
  maintenance('Đặt lịch bảo dưỡng'),
  charging('Trạm sạc');

  const ActivityFilter(this.label);
  final String label;

  bool includes(RescueOrder order) => switch (this) {
    all => true,
    sos =>
      order.serviceType != RescueServiceType.maintenance &&
          order.serviceType != RescueServiceType.charging,
    maintenance => order.serviceType == RescueServiceType.maintenance,
    charging => order.serviceType == RescueServiceType.charging,
  };
}
