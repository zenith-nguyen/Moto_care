import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_rescue_orders.dart';
import '../models/rescue_order.dart';
import '../models/activity_state.dart';
export '../models/activity_state.dart';
import '../models/activity_filter.dart';
import '../services/rescue_order_service.dart';

final initialRescueOrdersProvider = Provider<List<RescueOrder>>(
  (ref) => mockRescueOrders,
);

final activityProvider = NotifierProvider<ActivityController, ActivityState>(
  ActivityController.new,
);

class ActivityController extends Notifier<ActivityState> {
  @override
  ActivityState build() =>
      ActivityState(orders: ref.watch(initialRescueOrdersProvider));

  bool cancelOrder(String id) {
    final order = state.orderById(id);
    if (order == null || !order.status.isActive) return false;
    _replaceOrder(order.copyWith(status: RescueOrderStatus.cancelled));
    return true;
  }

  RescueOrder rebookOrder(
    String id, {
    required String userVehicle,
    required String locationAddress,
  }) {
    final original = state.orderById(id);
    if (original == null || original.status.isActive) {
      throw StateError('Order is not available for rebooking');
    }
    return createOrder(
      serviceType: original.serviceType,
      userVehicle: userVehicle,
      locationAddress: locationAddress,
    );
  }

  RescueOrder createOrder({
    required RescueServiceType serviceType,
    required String userVehicle,
    required String locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    String locationLandmark = '',
    String incidentDescription = '',
    String serviceOption = '',
    String vehicleType = '',
    Uint8List? incidentPhotoBytes,
    int? basePrice,
    int? travelFee,
    int discount = 0,
    String? partnerId,
    String? partnerName,
    RescuePaymentMethod paymentMethod = RescuePaymentMethod.cash,
    String voucherCode = '',
    List<RescueOrderItem> items = const [],
  }) {
    final order = ref
        .read(rescueOrderServiceProvider)
        .createOrder(
          hasActiveOrder: state.activeOrders.isNotEmpty,
          serviceType: serviceType,
          userVehicle: userVehicle,
          locationAddress: locationAddress,
          locationLatitude: locationLatitude,
          locationLongitude: locationLongitude,
          locationLandmark: locationLandmark,
          incidentDescription: incidentDescription,
          serviceOption: serviceOption,
          vehicleType: vehicleType,
          incidentPhotoBytes: incidentPhotoBytes,
          basePrice: basePrice,
          travelFee: travelFee,
          discount: discount,
          partnerId: partnerId,
          partnerName: partnerName,
          paymentMethod: paymentMethod,
          voucherCode: voucherCode,
          items: items,
        );
    state = ActivityState(
      orders: [order, ...state.orders],
      complaints: state.complaints,
    );
    return order;
  }

  bool rateOrder(String id, int rating) {
    final order = state.orderById(id);
    if (order == null ||
        order.status != RescueOrderStatus.completed ||
        rating < 1 ||
        rating > 5) {
      return false;
    }
    _replaceOrder(order.copyWith(rating: rating.toDouble()));
    return true;
  }

  bool reportOrder(String id, String message) {
    if (state.orderById(id) == null || message.trim().length < 10) return false;
    state = ActivityState(
      orders: state.orders,
      complaints: [
        ...state.complaints,
        RescueComplaint(
          orderId: id,
          message: message.trim(),
          createdAt: DateTime.now(),
        ),
      ],
    );
    return true;
  }

  void _replaceOrder(RescueOrder updated) {
    state = ActivityState(
      orders: [
        for (final order in state.orders)
          if (order.id == updated.id) updated else order,
      ],
      complaints: state.complaints,
    );
  }
}

final filteredActivityOrdersProvider = Provider.autoDispose
    .family<List<RescueOrder>, ActivityFilter>((ref, filter) {
      final orders =
          ref.watch(activityProvider).orders.where(filter.includes).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(orders);
    });
final completedOrderSummaryProvider =
    Provider<({List<RescueOrder> orders, int total, int maintenanceCount})>((
      ref,
    ) {
      final orders = ref
          .watch(activityProvider)
          .historyOrders
          .where((order) => order.status == RescueOrderStatus.completed)
          .toList();
      return (
        orders: List.unmodifiable(orders),
        total: orders.fold(0, (sum, order) => sum + order.totalPrice),
        maintenanceCount: orders
            .where(
              (order) => order.serviceType == RescueServiceType.maintenance,
            )
            .length,
      );
    });
