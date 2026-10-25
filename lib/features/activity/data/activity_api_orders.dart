import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/application/session_state.dart';
import '../../auth/domain/app_user.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/domain/order_status.dart';
import '../models/rescue_order.dart';

final activityApiOrdersProvider = FutureProvider<List<RescueOrder>>((
  ref,
) async {
  if (!ref.watch(runtimeApiIntegrationProvider)) return const [];
  final repository = ref.watch(ordersRepositoryProvider);
  // The customer is the owner of these orders, so their account identity is the
  // requester shown on the order. This avoids the "Chưa cập nhật" fallback when
  // the profile tab has not been opened/refreshed yet.
  final sessionState = ref.read(sessionControllerProvider);
  final requester = sessionState is SessionSignedIn
      ? sessionState.session.user
      : null;
  final summaries = await repository.listMine();
  final orders = await Future.wait(
    summaries.map((summary) async {
      final details = await repository.getById(summary.id);
      ParticipantContact? contact;
      if (summary.providerId != null && !summary.status.isTerminal) {
        try {
          contact = await repository.participantContact(summary.id);
        } catch (_) {
          // Contact is intentionally unavailable outside an active assignment.
        }
      }
      return _toLegacyOrder(details, summary.createdAt, contact, requester);
    }),
  );
  orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return List.unmodifiable(orders);
});

RescueOrder _toLegacyOrder(
  OrderDetails order,
  DateTime createdAt,
  ParticipantContact? contact,
  AppUser? requester,
) {
  final status = _status(order.status);
  final coordinates = order.customerLocation;
  return RescueOrder(
    id: order.id.toString(),
    orderCode: order.code,
    status: status,
    requesterName: requester?.name ?? '',
    requesterPhone: requester?.phone ?? '',
    serviceType: _serviceType(order.incidentType.name),
    userVehicle: order.vehicle?.displayName ?? 'Chưa có thông tin xe',
    locationAddress:
        '${coordinates.latitude.toStringAsFixed(6)}, ${coordinates.longitude.toStringAsFixed(6)}',
    locationLatitude: coordinates.latitude,
    locationLongitude: coordinates.longitude,
    providerName:
        contact?.name ??
        (order.providerId == null
            ? null
            : 'Thợ phụ trách #${order.providerId}'),
    providerPhone: contact?.phone,
    paymentMethod: RescuePaymentMethod.bankTransfer,
    awaitingPrepayment: order.status == OrderStatus.awaitingPrepayment,
    basePrice: _vnd(order.estimatedPrice.value),
    extraPartPrice: _vnd(order.extraCost.value),
    discount: _vnd(order.discountAmount.value),
    createdAt: createdAt,
    statusEvents: [RescueOrderEvent(status: status, occurredAt: createdAt)],
  );
}

int _vnd(String value) => int.parse(value.split('.').first);

RescueOrderStatus _status(OrderStatus status) => switch (status) {
  OrderStatus.awaitingPrepayment ||
  OrderStatus.pendingMatch ||
  OrderStatus.offered => RescueOrderStatus.pending,
  OrderStatus.accepted || OrderStatus.arrived => RescueOrderStatus.enRoute,
  OrderStatus.inProgress ||
  OrderStatus.awaitingPriceApproval ||
  OrderStatus.priceDisputed ||
  OrderStatus.awaitingPayment ||
  OrderStatus.paid => RescueOrderStatus.repairing,
  OrderStatus.completed => RescueOrderStatus.completed,
  OrderStatus.cancelled ||
  OrderStatus.refundPending ||
  OrderStatus.refunded => RescueOrderStatus.cancelled,
};

RescueServiceType _serviceType(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('lốp')) return RescueServiceType.flatTire;
  if (normalized.contains('xăng')) return RescueServiceType.outOfFuel;
  if (normalized.contains('bình')) return RescueServiceType.batteryJump;
  if (normalized.contains('ngập')) return RescueServiceType.floodedEngine;
  if (normalized.contains('kéo') || normalized.contains('cẩu')) {
    return RescueServiceType.towing;
  }
  return RescueServiceType.engineFailure;
}
