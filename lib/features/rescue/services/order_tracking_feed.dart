import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tracking_update.dart';

/// Override this provider with a WebSocket/SSE/repository adapter when available.
final orderTrackingFeedProvider = Provider<OrderTrackingFeed?>((ref) => null);

abstract interface class OrderTrackingFeed {
  Stream<TrackingUpdate> watchOrder(String orderId);
}
