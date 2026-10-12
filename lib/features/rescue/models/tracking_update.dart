import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'tracking_mechanic.dart';

/// One backend observation; route points are ordered from mechanic to incident.
class TrackingUpdate {
  TrackingUpdate({
    required this.orderId,
    required this.observedAt,
    required this.mechanic,
    required List<LatLng> route,
    this.customer,
    this.remainingDistanceKm,
    this.etaMinutes,
    this.mechanicDetails,
    this.arrived,
  }) : route = List.unmodifiable(route) {
    if (orderId.trim().isEmpty ||
        [mechanic, ?customer, ...route].any(
          (point) => !point.latitude.isFinite || !point.longitude.isFinite,
        ) ||
        (remainingDistanceKm != null &&
            (!remainingDistanceKm!.isFinite || remainingDistanceKm! < 0)) ||
        (etaMinutes != null && etaMinutes! < 0)) {
      throw ArgumentError('Invalid tracking observation');
    }
  }

  final String orderId;
  final DateTime observedAt;
  final LatLng mechanic;
  final LatLng? customer;
  final List<LatLng> route;
  final double? remainingDistanceKm;
  final int? etaMinutes;
  final TrackingMechanic? mechanicDetails;
  final bool? arrived;
}
