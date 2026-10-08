import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../activity/models/rescue_order.dart';
import '../../partner/models/partner_shop.dart';

/// A simulated path, never a Directions response or a mechanic GPS feed.
class OrderTrackingJourney {
  OrderTrackingJourney._(this.points);
  final List<LatLng> points;
  LatLng get customer => points.last;
  int get lastStep => points.length - 1;
  double get distanceKm => remainingKm(0, 0);

  static OrderTrackingJourney? fromOrder(RescueOrder order, PartnerShop? shop) {
    if (order.locationLatitude == null || order.locationLongitude == null) {
      return null;
    }
    final customer = LatLng(order.locationLatitude!, order.locationLongitude!);
    final start = shop == null
        ? LatLng(
            (customer.latitude + .0067).clamp(-90, 90),
            (customer.longitude - .00415).clamp(-180, 180),
          )
        : LatLng(shop.station.latitude, shop.station.longitude);
    final corner = LatLng(start.latitude, customer.longitude);
    final points = <LatLng>[start];
    for (final (from, to) in [(start, corner), (corner, customer)]) {
      for (var step = 1; step <= 8; step++) {
        final point = interpolate(from, to, step / 8);
        if (point != points.last) points.add(point);
      }
    }
    if (points.length == 1) points.add(customer);
    return OrderTrackingJourney._(List.unmodifiable(points));
  }

  static LatLng interpolate(LatLng from, LatLng to, double t) => LatLng(
    from.latitude + (to.latitude - from.latitude) * t,
    from.longitude + (to.longitude - from.longitude) * t,
  );

  LatLng positionAt(int step, double t) => step >= lastStep
      ? customer
      : interpolate(points[step], points[step + 1], t.clamp(0, 1));

  List<LatLng> remainingRoute(int step, double t) => [
    positionAt(step, t),
    ...points.skip(step + 1),
  ];

  double remainingKm(int step, double t) {
    final remaining = remainingRoute(step, t);
    var meters = 0.0;
    for (var index = 1; index < remaining.length; index++) {
      meters += Geolocator.distanceBetween(
        remaining[index - 1].latitude,
        remaining[index - 1].longitude,
        remaining[index].latitude,
        remaining[index].longitude,
      );
    }
    return meters / 1000;
  }
}
