import 'package:flutter/foundation.dart';

import 'rescue_order.dart';

@immutable
class RescueComplaint {
  const RescueComplaint({
    required this.orderId,
    required this.message,
    required this.createdAt,
  });

  final String orderId;
  final String message;
  final DateTime createdAt;
}

@immutable
class ActivityState {
  ActivityState({
    required List<RescueOrder> orders,
    List<RescueComplaint> complaints = const [],
  }) : orders = List.unmodifiable(orders),
       complaints = List.unmodifiable(complaints);

  final List<RescueOrder> orders;
  final List<RescueComplaint> complaints;

  List<RescueOrder> get activeOrders =>
      orders.where((order) => order.status.isActive).toList();

  List<RescueOrder> get historyOrders =>
      orders.where((order) => !order.status.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  RescueOrder? orderById(String? id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }
}
