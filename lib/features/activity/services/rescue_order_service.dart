import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_rescue_orders.dart';
import '../models/rescue_order.dart';

final rescueOrderClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
final rescueOrderServiceProvider = Provider<RescueOrderService>(
  (ref) => RescueOrderService(clock: ref.watch(rescueOrderClockProvider)),
);

class RescueOrderService {
  RescueOrderService({required this.clock});
  final DateTime Function() clock;
  int _sequence = 0;
  RescueOrder createOrder({
    required bool hasActiveOrder,
    required RescueServiceType serviceType,
    required String userVehicle,
    required String locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    String locationLandmark = '',
    String incidentDescription = '',
    String serviceOption = '',
    String vehicleType = '',
    Uint8List? incidentPhotoBytes,
    int? basePrice,
    int? travelFee,
    int discount = 0,
    String? partnerId,
    String? partnerName,
    RescuePaymentMethod paymentMethod = RescuePaymentMethod.cash,
    String voucherCode = '',
    List<RescueOrderItem> items = const [],
  }) {
    if (hasActiveOrder) {
      throw StateError('An active rescue order already exists');
    }
    if (userVehicle.trim().isEmpty || locationAddress.trim().isEmpty) {
      throw ArgumentError('Vehicle and location are required');
    }
    final now = clock();
    final price = basePrice ?? mockBasePrice(serviceType);
    final sequence = (++_sequence).toString().padLeft(3, '0');
    final order = RescueOrder(
      id: 'order-${now.microsecondsSinceEpoch}-$sequence',
      orderCode:
          'MC-${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-$sequence',
      status: RescueOrderStatus.pending,
      serviceType: serviceType,
      userVehicle: userVehicle.trim(),
      locationAddress: locationAddress.trim(),
      locationLandmark: locationLandmark.trim(),
      incidentDescription: incidentDescription.trim(),
      serviceOption: serviceOption.trim(),
      vehicleType: vehicleType.trim(),
      incidentPhotoBytes: incidentPhotoBytes == null
          ? null
          : Uint8List.fromList(incidentPhotoBytes).asUnmodifiableView(),
      basePrice: price,
      travelFee: travelFee ?? (price < 30000 ? price : 30000),
      extraPartPrice: 0,
      discount: discount,
      partnerId: partnerId,
      partnerName: partnerName,
      paymentMethod: paymentMethod,
      voucherCode: voucherCode,
      items: items,
      createdAt: now,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
    );
    return order;
  }
}
