import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../partner/providers/partner_provider.dart';
import '../models/order_tracking_journey.dart';
import '../models/order_tracking_state.dart';
import '../services/order_tracking_service.dart';

export '../models/order_tracking_state.dart';

typedef TrackingKey = (Object, String?);
final orderTrackingProvider = NotifierProvider.autoDispose
    .family<OrderTrackingController, OrderTrackingState, TrackingKey>(
      OrderTrackingController.new,
    );

class OrderTrackingController extends Notifier<OrderTrackingState> {
  OrderTrackingController(this.key);
  final TrackingKey key;
  Timer? _timer;
  bool _enabled = false;
  @override
  OrderTrackingState build() {
    final order = ref.read(activityProvider).orderById(key.$2);
    final shops = ref
        .read(partnerShopsProvider)
        .where((shop) => shop.id == order?.partnerId);
    ref.onDispose(() => _timer?.cancel());
    ref.listen(activityProvider, (_, next) {
      if (!_active(next.orderById(key.$2))) stop();
    });
    return OrderTrackingState(
      order == null
          ? null
          : OrderTrackingJourney.fromOrder(
              order,
              shops.isEmpty ? null : shops.first,
            ),
    );
  }

  bool _active(RescueOrder? order) =>
      order?.status == RescueOrderStatus.pending ||
      order?.status == RescueOrderStatus.enRoute;
  bool get canMove =>
      _enabled &&
      !state.arrived &&
      state.journey != null &&
      _active(ref.read(activityProvider).orderById(key.$2));
  void setEnabled(bool value) {
    _enabled = value;
    if (!canMove) {
      stop();
      return;
    }
    if (_timer?.isActive == true) return;
    _timer = ref.read(orderTrackingServiceProvider).start(() {
      if (!canMove) {
        stop();
        return;
      }
      state = OrderTrackingState(state.journey, step: state.step + 1);
      if (state.arrived) stop();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
