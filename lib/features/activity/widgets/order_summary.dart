import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/rescue_order.dart';
import '../theme/activity_theme.dart';

final _currency = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);
final _orderDate = DateFormat('dd/MM/yyyy • HH:mm', 'vi');

String formatOrderPrice(int value) => _currency.format(value);
String formatOrderDate(DateTime value) => _orderDate.format(value.toLocal());

IconData serviceIcon(RescueServiceType service) => switch (service) {
  RescueServiceType.flatTire => Icons.tire_repair,
  RescueServiceType.outOfFuel => Icons.local_gas_station_rounded,
  RescueServiceType.engineFailure => Icons.build_rounded,
  RescueServiceType.batteryJump => Icons.battery_charging_full_rounded,
  RescueServiceType.floodedEngine => Icons.water_drop_rounded,
  RescueServiceType.towing => Icons.local_shipping_rounded,
  RescueServiceType.maintenance => Icons.build_circle_rounded,
  RescueServiceType.nightRescue => Icons.nights_stay_rounded,
  RescueServiceType.charging => Icons.bolt_rounded,
};

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final RescueOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RescueOrderStatus.completed => ActivityTheme.green,
      RescueOrderStatus.cancelled => ActivityTheme.red,
      _ => ActivityTheme.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OrderEmptyState extends StatelessWidget {
  const OrderEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.history_rounded,
  });
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: ActivityTheme.red),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ActivityTheme.mutedText,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  );
}
