import 'package:flutter/material.dart';

import '../../activity/models/rescue_order.dart';
import '../theme/home_theme.dart';

enum HomeService {
  tire(
    'Vá xe',
    Icons.tire_repair_rounded,
    HomeColors.red,
    RescueServiceType.flatTire,
  ),
  battery(
    'Kích bình\nđiện',
    Icons.battery_charging_full_rounded,
    HomeColors.red,
    RescueServiceType.batteryJump,
  ),
  fuel(
    'Cứu hộ\nHết xăng',
    Icons.local_gas_station_rounded,
    HomeColors.red,
    RescueServiceType.outOfFuel,
  ),
  flood(
    'Sửa ngập\nnước',
    Icons.water_drop_rounded,
    HomeColors.red,
    RescueServiceType.floodedEngine,
  ),
  charging('Trạm sạc\ngần nhất', Icons.bolt_rounded, HomeColors.red, null),
  towing(
    'Xe cẩu\nkéo',
    Icons.local_shipping_rounded,
    HomeColors.red,
    RescueServiceType.towing,
  ),
  maintenance(
    'Đặt lịch\nbảo dưỡng',
    Icons.build_rounded,
    HomeColors.red,
    RescueServiceType.maintenance,
  ),
  all('Tất cả\ndịch vụ', Icons.grid_view_rounded, HomeColors.red, null),
  night(
    'Cứu hộ đêm\n24/7',
    Icons.nights_stay_rounded,
    HomeColors.red,
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
}

class HomeServiceGrid extends StatelessWidget {
  const HomeServiceGrid({super.key, required this.onSelected});
  final ValueChanged<HomeService> onSelected;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisSpacing: 8,
      mainAxisSpacing: 10,
      mainAxisExtent: 108 + (scale - 1) * 55,
      children: [
        for (final service in HomeService.homeItems)
          ServiceTile(
            key: ValueKey('home-service-${service.name}'),
            label: service.label,
            icon: service.icon,
            color: service.color,
            onTap: () => onSelected(service),
          ),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = HomeColors.red,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: HomeColors.surface,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
