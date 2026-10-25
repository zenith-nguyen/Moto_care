import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/realtime/realtime_session_coordinator.dart';
import '../../activity/models/rescue_order.dart';
import '../../activity/providers/activity_provider.dart';
import '../../partner/providers/partner_provider.dart';
import '../models/order_tracking_journey.dart';
import '../models/order_tracking_state.dart';
import '../services/order_tracking_service.dart';
import '../services/order_tracking_feed.dart';
import '../models/tracking_update.dart';

export '../models/order_tracking_state.dart';

typedef TrackingKey = (Object, String?);
final orderTrackingUpdatesProvider = StreamProvider.autoDispose
    .family<TrackingUpdate, TrackingKey>((ref, key) {
      final feed = ref.watch(orderTrackingFeedProvider);
      final order = ref.watch(
        activityProvider.select((state) => state.orderById(key.$2)),
      );
      if (feed == null || order == null || !order.status.isActive) {
        return const Stream.empty();
      }
      return feed.watchOrder(order.id);
    });
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
    final liveMode =
        ref.watch(runtimeApiIntegrationProvider) ||
        ref.watch(orderTrackingFeedProvider) != null;
    final order = ref.read(activityProvider).orderById(key.$2);
    final shops = ref
        .read(partnerShopsProvider)
        .where((shop) => shop.id == order?.partnerId);
    ref.onDispose(() => _timer?.cancel());
    // In real API mode, join the order's realtime room so the backend streams
    // the assigned provider's GPS (provider.location_updated) to the tracking
    // feed. Gated on the API flag (not liveMode) so injected test feeds never
    // touch the real socket connection.
    if (ref.read(runtimeApiIntegrationProvider) &&
        order != null &&
        order.status.isActive) {
      final target = int.tryParse(order.id);
      if (target != null) {
        final coordinator = ref.read(realtimeSessionCoordinatorProvider);
        coordinator.followOrder(target);
        ref.onDispose(coordinator.leaveOrder);
      }
    }
    ref.listen(activityProvider, (_, next) {
      if (!_active(next.orderById(key.$2))) stop();
    });
    ref.listen(orderTrackingUpdatesProvider(key), (_, next) {
      if (!ref.mounted ||
          !liveMode ||
          ref.read(activityProvider).orderById(key.$2)?.status.isActive !=
              true) {
        return;
      }
      if (next.hasError) {
        state = OrderTrackingState(
          state.journey,
          step: state.step,
          liveMode: true,
          update: state.update,
          feedError: 'Mất kết nối · Đang hiển thị vị trí gần nhất',
        );
      } else if (next.value case final update?) {
        if (update.orderId != key.$2 ||
            (state.update != null &&
                update.observedAt.isBefore(state.update!.observedAt))) {
          return;
        }
        state = OrderTrackingState(
          state.journey,
          liveMode: true,
          update: update,
        );
      }
    });
    return OrderTrackingState(
      liveMode || order == null
          ? null
          : OrderTrackingJourney.fromOrder(
              order,
              shops.isEmpty ? null : shops.first,
            ),
      liveMode: liveMode,
    );
  }

  bool _active(RescueOrder? order) =>
      order?.status == RescueOrderStatus.pending ||
      order?.status == RescueOrderStatus.enRoute;
  bool get canMove =>
      _enabled &&
      !state.liveMode &&
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
