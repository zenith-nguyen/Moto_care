import 'package:flutter/material.dart';

import '../../activity/models/rescue_order.dart';
import '../theme/home_theme.dart';

enum HomeService {
  tire(
    'Vá xe',
    Icons.tire_repair_rounded,
    HomeColors.text,
    RescueServiceType.flatTire,
  ),
  battery(
    'Kích bình\nđiện',
    Icons.battery_charging_full_rounded,
    Color(0xFFF9A825),
    RescueServiceType.batteryJump,
  ),
  fuel(
    'Cứu hộ\nHết xăng',
    Icons.local_gas_station_rounded,
    Color(0xFFEA580C),
    RescueServiceType.outOfFuel,
  ),
  flood(
    'Sửa ngập\nnước',
    Icons.water_drop_rounded,
    Color(0xFF0288D1),
    RescueServiceType.floodedEngine,
  ),
  charging('Trạm sạc\ngần nhất', Icons.bolt_rounded, Color(0xFF16A34A), null),
  towing(
    'Xe cẩu\nkéo',
    Icons.local_shipping_rounded,
    Color(0xFF2563EB),
    RescueServiceType.towing,
  ),
  maintenance(
    'Đặt lịch\nbảo dưỡng',
    Icons.build_rounded,
    HomeColors.text,
    RescueServiceType.maintenance,
  ),
  all('Tất cả\ndịch vụ', Icons.grid_view_rounded, HomeColors.red, null),
  night(
    'Cứu hộ đêm\n24/7',
    Icons.nights_stay_rounded,
    Color(0xFF4F46E5),
    RescueServiceType.nightRescue,
  );

  static const homeItems = [
    tire,
    battery,
    fuel,
    flood,
    charging,
    towing,
    maintenance,
    all,
  ];

  const HomeService(this.label, this.icon, this.color, this.orderType);
  final String label;
  final IconData icon;
  final Color color;
  final RescueServiceType? orderType;
  String get title => label.replaceAll('\n', ' ');
  String get partnerRoute => '/partners?service=${Uri.encodeComponent(title)}';
}
