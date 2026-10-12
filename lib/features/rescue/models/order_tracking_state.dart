import 'order_tracking_journey.dart';
import 'tracking_update.dart';

class OrderTrackingState {
  const OrderTrackingState(
    this.journey, {
    this.step = 0,
    this.liveMode = false,
    this.update,
    this.feedError,
  });
  final OrderTrackingJourney? journey;
  final int step;
  final bool liveMode;
  final TrackingUpdate? update;
  final String? feedError;
  bool get arrived => liveMode
      ? update?.arrived == true
      : journey != null &&
            (step >= journey!.lastStep || journey!.distanceKm < .001);
}
