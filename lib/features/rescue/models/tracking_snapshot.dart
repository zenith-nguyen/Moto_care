import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'tracking_mechanic.dart';

class TrackingRoute {
  const TrackingRoute({
    required this.customer,
    required this.mechanic,
    required this.points,
    required this.fullRoute,
  });
  final LatLng customer;
  final LatLng? mechanic;
  final List<LatLng> points, fullRoute;
}

class TrackingSnapshot {
  const TrackingSnapshot(
    this.displayStep,
    this.heading,
    this.badge,
    this.subtitle, {
    required this.map,
    required this.mechanic,
    required this.serviceLabel,
    required this.distanceLabel,
    required this.etaLabel,
    required this.statusLabel,
    required this.isSimulated,
    this.feedNotice,
  });
  final int displayStep;
  final String heading, badge, subtitle;
  final TrackingRoute? map;
  final TrackingMechanic mechanic;
  final String serviceLabel, distanceLabel, etaLabel, statusLabel;
  final bool isSimulated;
  final String? feedNotice;
}
