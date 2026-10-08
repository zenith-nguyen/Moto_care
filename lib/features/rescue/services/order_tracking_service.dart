import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/models/rescue_order.dart';
import '../models/order_tracking_journey.dart';
import '../models/tracking_mechanic.dart';
import '../models/tracking_snapshot.dart';

export '../models/tracking_mechanic.dart';
export '../models/tracking_snapshot.dart';

const trackingInterval = Duration(milliseconds: 1500);

final trackingMechanicProvider = Provider<TrackingMechanic>(
  (ref) => const TrackingMechanic(),
);

final orderTrackingServiceProvider = Provider<OrderTrackingService>(
  (ref) => const OrderTrackingService(),
);

class OrderTrackingService {
  const OrderTrackingService();
  Timer start(void Function() advance) =>
      Timer.periodic(trackingInterval, (_) => advance());
  TrackingSnapshot snapshot(
    RescueOrder order,
    OrderTrackingJourney? journey,
    int step,
    double progress,
  ) {
    final arrived =
        journey != null &&
        (step >= journey.lastStep || journey.distanceKm < .001);
    final displayStep =
        journey != null &&
            (order.status == RescueOrderStatus.repairing ||
                order.status == RescueOrderStatus.completed)
        ? journey.lastStep
        : step;
    final remaining = journey?.remainingKm(step, progress);
    final minutes = journey == null || journey.distanceKm == 0
        ? 0
        : math.max(1, (5 * (remaining ?? 0) / journey.distanceKm).ceil());
    final (heading, badge, subtitle) = switch (order.status) {
      RescueOrderStatus.cancelled => (
        'Đơn cứu hộ đã hủy',
        'ĐÃ HỦY',
        'Lộ trình đã dừng. Bạn có thể đặt một đơn mới.',
      ),
      RescueOrderStatus.completed => (
        'Cứu hộ đã hoàn tất',
        'HOÀN TẤT',
        'Cảm ơn bạn đã sử dụng MotoCare.',
      ),
      RescueOrderStatus.repairing => (
        'Thợ đang xử lý sự cố',
        'ĐANG SỬA',
        'Thợ đã đến và đang kiểm tra xe của bạn.',
      ),
      _ when journey == null => (
        'Đang chuẩn bị lộ trình',
        'CHỜ VỊ TRÍ',
        'Vị trí sự cố chưa có tọa độ để theo dõi.',
      ),
      _ when arrived => (
        'Thợ đã đến vị trí của bạn',
        'ĐÃ ĐẾN',
        'Đã đến điểm SOS • 0.0 km',
      ),
      _ => (
        'Thợ đang trên đường đến',
        'ĐANG ĐẾN',
        'Dự kiến đến trong $minutes phút • ${remaining!.toStringAsFixed(1)} km',
      ),
    };
    return TrackingSnapshot(displayStep, heading, badge, subtitle);
  }
}
