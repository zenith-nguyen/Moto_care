import 'package:flutter/foundation.dart';

import 'rescue_order.dart';

enum RescueProgressState { done, active, upcoming }

@immutable
class RescueProgressStep {
  const RescueProgressStep({
    required this.label,
    required this.state,
    required this.time,
  });
  final String label;
  final RescueProgressState state;
  final String time;
}

@immutable
class OrderTimelineEntry {
  const OrderTimelineEntry({
    required this.time,
    required this.date,
    required this.description,
    required this.isCurrent,
    required this.isCancelled,
  });
  final String time;
  final String date;
  final String description;
  final bool isCurrent;
  final bool isCancelled;
}

@immutable
class OrderDetails {
  OrderDetails({
    required this.order,
    required this.statusLabel,
    required this.requesterName,
    required this.requesterPhone,
    required this.mechanicName,
    required this.mechanicInitials,
    required this.mechanicPlate,
    required List<RescueProgressStep> steps,
    required List<OrderTimelineEntry> timeline,
  }) : steps = List.unmodifiable(steps),
       timeline = List.unmodifiable(timeline);

  final RescueOrder order;
  final String statusLabel;
  final String requesterName;
  final String requesterPhone;
  final String mechanicName;
  final String mechanicInitials;
  final String mechanicPlate;
  final List<RescueProgressStep> steps;
  final List<OrderTimelineEntry> timeline;
}
