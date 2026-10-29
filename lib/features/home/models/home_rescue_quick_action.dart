import '../../activity/models/rescue_order.dart';

enum HomeRescueQuickAction {
  all('Tất cả ⚡', '', null),
  battery('🔋 Kích bình', 'Kích bình', RescueServiceType.batteryJump),
  flood('🌊 Ngập nước', 'Ngập nước', RescueServiceType.floodedEngine),
  towing('🚚 Xe kéo', 'Xe cẩu kéo', RescueServiceType.towing),
  repair('🔧 Sửa tại chỗ', 'Chết máy', RescueServiceType.engineFailure);

  const HomeRescueQuickAction(this.label, this.searchQuery, this.serviceType);

  final String label;
  final String searchQuery;
  final RescueServiceType? serviceType;
}
