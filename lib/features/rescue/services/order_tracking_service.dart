import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../activity/models/rescue_order.dart';
import '../../activity/widgets/order_summary.dart';
import '../../chat/models/chat_conversation.dart';
import '../models/order_tracking_journey.dart';
import '../models/tracking_mechanic.dart';
import '../models/tracking_snapshot.dart';
import '../models/tracking_update.dart';

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
    double progress, {
    bool liveMode = false,
    TrackingUpdate? update,
    String? feedError,
    TrackingMechanic fallbackMechanic = const TrackingMechanic(),
  }) {
    final arrived = liveMode
        ? update?.arrived == true
        : journey != null &&
              (step >= journey.lastStep || journey.distanceKm < .001);
    final displayStep =
        journey != null &&
            (order.status == RescueOrderStatus.repairing ||
                order.status == RescueOrderStatus.completed)
        ? journey.lastStep
        : step;
    final customer = order.locationLatitude != null
        ? LatLng(order.locationLatitude!, order.locationLongitude!)
        : update?.customer;
    final map = customer == null
        ? null
        : liveMode
        ? TrackingRoute(
            customer: customer,
            mechanic: update?.mechanic,
            points: update?.route ?? const [],
            fullRoute: update?.route ?? const [],
          )
        : journey == null
        ? null
        : TrackingRoute(
            customer: customer,
            mechanic: journey.positionAt(displayStep, progress),
            points: journey.remainingRoute(displayStep, progress),
            fullRoute: journey.points,
          );
    final remaining = arrived
        ? 0.0
        : liveMode
        ? update?.remainingDistanceKm ??
              (update != null && update.route.length >= 2
                  ? OrderTrackingJourney.routeDistanceKm(update.route)
                  : order.providerDistanceKm)
        : journey?.remainingKm(displayStep, progress);
    final minutes = arrived
        ? 0
        : liveMode
        ? update?.etaMinutes ?? order.etaMinutes
        : journey == null
        ? null
        : journey.distanceKm == 0
        ? 0
        : math.max(1, (5 * (remaining ?? 0) / journey.distanceKm).ceil());
    final distanceLabel = remaining == null
        ? '—'
        : '${remaining.toStringAsFixed(1)} km';
    final etaLabel = minutes == null ? '—' : '$minutes phút';
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
      _ when map == null => (
        'Đang chuẩn bị lộ trình',
        'CHỜ VỊ TRÍ',
        'Vị trí sự cố chưa có tọa độ để theo dõi.',
      ),
      _ when liveMode && update == null => (
        'Đang chờ vị trí thợ',
        'Đang kết nối',
        'Vị trí thợ sẽ cập nhật ngay khi có dữ liệu.',
      ),
      _ when arrived => (
        'Thợ đã đến vị trí của bạn',
        'ĐÃ ĐẾN',
        'Đã đến điểm SOS • 0.0 km',
      ),
      _ => (
        'Thợ đang trên đường đến',
        'ĐANG ĐẾN',
        minutes == null
            ? 'Đang cập nhật thời gian đến • $distanceLabel'
            : 'Dự kiến đến trong $etaLabel • $distanceLabel',
      ),
    };
    final details = update?.mechanicDetails;
    final mechanic = TrackingMechanic(
      name:
          details?.name ??
          order.providerName ??
          (liveMode ? 'Đang chờ thông tin thợ' : fallbackMechanic.name),
      shop:
          details?.shop ??
          order.partnerName ??
          (liveMode ? '' : fallbackMechanic.shop),
      plate:
          details?.plate ??
          order.providerPlate ??
          (liveMode ? 'Chưa cập nhật biển số' : fallbackMechanic.plate),
      vehicle: details?.vehicle ?? (liveMode ? '' : fallbackMechanic.vehicle),
      rating: details?.rating ?? order.rating ?? fallbackMechanic.rating,
      phoneNumber: details?.phoneNumber ?? order.providerPhone,
      avatarUrl: details?.avatarUrl,
    );
    return TrackingSnapshot(
      displayStep,
      heading,
      badge,
      subtitle,
      map: map,
      mechanic: mechanic,
      distanceLabel: distanceLabel,
      etaLabel: etaLabel,
      serviceLabel: switch (order.serviceType) {
        RescueServiceType.maintenance => 'Bảo dưỡng xe máy',
        RescueServiceType.towing => 'Cẩu kéo xe máy',
        RescueServiceType.charging => 'Sạc xe',
        _ => 'Cứu hộ xe máy',
      },
      statusLabel: !order.status.isActive
          ? order.status.label
          : order.status == RescueOrderStatus.repairing
          ? 'Đang xử lý sự cố'
          : map == null
          ? 'Chờ vị trí sự cố'
          : liveMode && update == null
          ? 'Đang kết nối'
          : arrived
          ? 'Thợ đã đến'
          : 'Đang trên đường đến',
      isSimulated: !liveMode,
      feedNotice: feedError == null
          ? null
          : update == null
          ? 'Mất kết nối · Chưa nhận được vị trí thợ'
          : feedError,
    );
  }

  ChatConversation conversation(RescueOrder order, TrackingSnapshot snapshot) =>
      ChatConversation(
        mechanicName: snapshot.mechanic.name,
        avatarInitials: snapshot.mechanic.initials,
        licensePlate: snapshot.mechanic.plate,
        phoneNumber: snapshot.mechanic.phoneNumber ?? '',
        status: switch (order.status) {
          RescueOrderStatus.repairing => RescueStatus.repairing,
          RescueOrderStatus.completed => RescueStatus.completed,
          RescueOrderStatus.pending => RescueStatus.accepted,
          _ => RescueStatus.arriving,
        },
        statusLabel: snapshot.statusLabel,
        lastMessage:
            'Trao đổi về đơn ${order.orderCode}: ${order.serviceType.label}.',
        timeLabel: formatOrderDate(order.createdAt),
      );
}
