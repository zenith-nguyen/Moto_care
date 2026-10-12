import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../activity/models/rescue_order.dart';
import '../models/service_catalog_model.dart';
import '../theme/station_detail_theme.dart';

String formatCatalogPrice(int price) =>
    '${NumberFormat.decimalPattern('vi').format(price)} đ';

class ServiceCatalogIconBox extends StatelessWidget {
  const ServiceCatalogIconBox({super.key, required this.serviceType});
  final RescueServiceType serviceType;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: StationDetailColors.catalogTint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(
      switch (serviceType) {
        RescueServiceType.flatTire => Icons.tire_repair_rounded,
        RescueServiceType.batteryJump => Icons.battery_charging_full_rounded,
        RescueServiceType.towing => Icons.local_shipping_outlined,
        RescueServiceType.outOfFuel => Icons.local_gas_station_outlined,
        RescueServiceType.charging => Icons.ev_station_outlined,
        _ => Icons.build_outlined,
      },
      size: 27,
      color: StationDetailColors.red,
      shadows: const [
        Shadow(color: Color(0x1AE53935), blurRadius: 5, offset: Offset(0, 2)),
      ],
    ),
  );
}

class ServiceFulfillmentBadge extends StatelessWidget {
  const ServiceFulfillmentBadge({super.key, required this.fulfillment});
  final ServiceFulfillment fulfillment;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (fulfillment) {
      ServiceFulfillment.onSite => (Icons.two_wheeler_rounded, 'Tận nơi'),
      ServiceFulfillment.toWorkshop => (
        Icons.local_shipping_outlined,
        'Chở về tiệm',
      ),
      ServiceFulfillment.atStation => (Icons.storefront_outlined, 'Tại trạm'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: StationDetailColors.catalogTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: StationDetailColors.red),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: StationDetailColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
