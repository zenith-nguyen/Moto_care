import 'package:flutter/foundation.dart';

import 'rescue_order.dart';

@immutable
class RescueOrderItem {
  RescueOrderItem({
    required this.packageId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.serviceType,
  }) {
    if (packageId.trim().isEmpty ||
        name.trim().isEmpty ||
        unitPrice < 0 ||
        quantity < 1 ||
        quantity > 9) {
      throw ArgumentError('Invalid rescue service item');
    }
  }
  final String packageId;
  final String name;
  final int unitPrice;
  final int quantity;
  final RescueServiceType serviceType;
  int get total => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'packageId': packageId,
    'name': name,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'serviceType': serviceType.label,
  };
  factory RescueOrderItem.fromJson(Map<String, dynamic> json) =>
      RescueOrderItem(
        packageId: json['packageId'] as String,
        name: json['name'] as String,
        unitPrice: (json['unitPrice'] as num).toInt(),
        quantity: (json['quantity'] as num).toInt(),
        serviceType: RescueServiceType.fromValue(json['serviceType'] as String),
      );
}

enum RescuePaymentMethod {
  cash('cash', 'Tiền mặt'),
  momo('momo', 'Ví MoMo'),
  motoCare('motocare', 'Ví MotoCare');

  const RescuePaymentMethod(this.value, this.label);
  final String value;
  final String label;
  static RescuePaymentMethod fromValue(String value) => values.firstWhere(
    (method) => method.value == value,
    orElse: () => throw FormatException('Unknown payment method: $value'),
  );
}
