import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/realtime/realtime_client.dart';
import '../../../core/realtime/realtime_event.dart';
import '../models/tracking_update.dart';

/// In live mode, the tracking feed is backed by the realtime client: the
/// backend emits `provider.location_updated` to the order room whenever the
/// assigned provider reports GPS, and this maps those events into
/// [TrackingUpdate]s for the tracking map. The offline demo returns null so the
/// screen keeps its simulated journey.
final orderTrackingFeedProvider = Provider<OrderTrackingFeed?>((ref) {
  if (!ref.watch(runtimeApiIntegrationProvider)) return null;
  return RealtimeOrderTrackingFeed(ref.watch(realtimeClientProvider));
});

abstract interface class OrderTrackingFeed {
  Stream<TrackingUpdate> watchOrder(String orderId);
}

class RealtimeOrderTrackingFeed implements OrderTrackingFeed {
  RealtimeOrderTrackingFeed(this._client);

  final RealtimeClient _client;

  @override
  Stream<TrackingUpdate> watchOrder(String orderId) {
    final target = int.tryParse(orderId);
    if (target == null) return const Stream.empty();
    return _client.events
        .where(
          (event) =>
              event is ProviderLocationUpdated && event.orderId == target,
        )
        .cast<ProviderLocationUpdated>()
        .map(
          (event) => TrackingUpdate(
            orderId: orderId,
            observedAt: event.updatedAt,
            mechanic: LatLng(event.latitude, event.longitude),
            route: const [],
          ),
        );
  }
}
