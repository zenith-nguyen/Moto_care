import 'order_tracking_journey.dart';

class OrderTrackingState {
  const OrderTrackingState(this.journey, {this.step = 0});
  final OrderTrackingJourney? journey;
  final int step;
  bool get arrived =>
      journey != null &&
      (step >= journey!.lastStep || journey!.distanceKm < .001);
}
