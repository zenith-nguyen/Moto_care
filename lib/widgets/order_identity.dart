import 'package:flutter/material.dart';
import '../data/home_catalog.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'ui.dart';

/// Local illustration, never a car photo reused for a motorcycle.
class VehicleThumbnail extends StatelessWidget {
  const VehicleThumbnail({super.key, required this.vehicle, this.size = 58});
  final String vehicle;
  final double size;
  @override
  Widget build(BuildContext context) {
    final label = vehicleLabel(vehicle);
    final icon = label == 'Ô tô'
        ? Icons.directions_car_rounded
        : label == 'Xe tay ga'
            ? Icons.electric_moped_rounded
            : Icons.two_wheeler_rounded;
    return Semantics(
        label: 'Minh hoạ $label: $vehicle',
        image: true,
        child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border)),
            child: Icon(icon, size: size * .65, color: AppColors.primary)));
  }
}

class OrderIdentityCard extends StatelessWidget {
  const OrderIdentityCard(
      {super.key, required this.offer, this.showCustomer = true});
  final OrderOffer offer;
  final bool showCustomer;
  @override
  Widget build(BuildContext context) => SurfaceCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        VehicleThumbnail(vehicle: offer.vehicle),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(offer.orderId,
              style: AppTypography.label.copyWith(color: AppColors.primary)),
          if (showCustomer)
            Text(offer.customerName, style: AppTypography.label),
          Text('${offer.vehicle} · ${offer.issue}',
              style: appText(12, color: AppColors.textSub)),
          if (offer.plate.isNotEmpty)
            Text(offer.plate, style: AppTypography.caption),
        ])),
      ]));
}

/// Service id inferred from the order's issue text, or null when unknown.
String? orderServiceId(String issue) {
  final key = homeSearchKey(issue);
  bool has(List<String> words) => words.any(key.contains);
  if (has(['binh', 'kich'])) return 'battery';
  if (has(['lop'])) return 'tire';
  if (has(['ngap'])) return 'flood';
  if (has(['keo', 'di chuyen'])) return 'tow';
  if (has(['xang', 'nhien lieu'])) return 'fuel';
  if (has(['nhot', 'bao duong'])) return 'maintenance';
  if (has(['chet may', 'sua', 'su co'])) return 'repair';
  return null;
}

/// Illustrative photo for an order by service **and** vehicle class; never a
/// car photo for a two-wheeler. Null means "no suitable photo" (neutral panel).
String? orderPhotoFor(String issue, String vehicle) {
  final service = orderServiceId(issue);
  if (service == null) return null;
  if (vehicleLabel(vehicle) != 'Ô tô') {
    return switch (service) {
      'fuel' => 'assets/images/order_fuel_motorbike.png',
      'tire' => 'assets/images/order_tire_motorbike.jpg',
      // Battery is an illustration of the job type, shown for any vehicle
      // (it is not a photo of the customer's vehicle).
      'battery' => 'assets/images/order_battery_car.jpg',
      _ => null,
    };
  }
  return switch (service) {
    'battery' => 'assets/images/order_battery_car.jpg',
    'tow' => 'assets/images/order_tow_car.jpg',
    'flood' => 'assets/images/order_flood_car.jpg',
    // No dedicated order photo: reuse the approved catalog photo of the service.
    _ => homeServices.firstWhere((e) => e.id == service).image,
  };
}

/// Per-photo crop so the subject survives the wide thumbnail.
Alignment _alignmentFor(String path) => switch (path) {
      // Portrait photo: keep the wheel and the hands working on it.
      'assets/images/order_tire_motorbike.jpg' => const Alignment(0, -.45),
      // Landscape photo: keep the nozzle going into the tank.
      'assets/images/order_fuel_motorbike.png' => const Alignment(.15, .1),
      _ => Alignment.center,
    };

/// Rounded service photo for an order card. Illustration only, not evidence of
/// the customer's actual vehicle. No icon is drawn on top of it.
class OrderPhoto extends StatelessWidget {
  const OrderPhoto(
      {super.key,
      required this.issue,
      required this.vehicle,
      required this.width,
      required this.height});
  final String issue, vehicle;
  final double width, height;
  @override
  Widget build(BuildContext context) {
    final path = orderPhotoFor(issue, vehicle);
    return Semantics(
        label: 'Ảnh minh hoạ dịch vụ: $issue',
        image: true,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
                width: width,
                height: height,
                child: path == null
                    ? const ColoredBox(color: AppColors.surfaceSoft)
                    : Image.asset(path,
                        fit: BoxFit.cover,
                        alignment: _alignmentFor(path),
                        excludeFromSemantics: true))));
  }
}
