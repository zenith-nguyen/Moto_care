import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_rescue_orders.dart';
import '../models/rescue_order.dart';

final initialRescueOrdersProvider = Provider<List<RescueOrder>>(
  (ref) => mockRescueOrders,
);

final activityProvider = NotifierProvider<ActivityController, ActivityState>(
  ActivityController.new,
);

@immutable
class RescueComplaint {
  const RescueComplaint({
    required this.orderId,
    required this.message,
    required this.createdAt,
  });

  final String orderId;
  final String message;
  final DateTime createdAt;
}

@immutable
class ActivityState {
  ActivityState({
    required List<RescueOrder> orders,
    List<RescueComplaint> complaints = const [],
  }) : orders = List.unmodifiable(orders),
       complaints = List.unmodifiable(complaints);

  final List<RescueOrder> orders;
  final List<RescueComplaint> complaints;

  List<RescueOrder> get activeOrders =>
      orders.where((order) => order.status.isActive).toList();

  List<RescueOrder> get historyOrders =>
      orders.where((order) => !order.status.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  RescueOrder? orderById(String? id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }
}

class ActivityController extends Notifier<ActivityState> {
  int _sequence = 0;

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
    if (state.activeOrders.isNotEmpty) {
      throw StateError('An active rescue order already exists');
    }
    if (userVehicle.trim().isEmpty || locationAddress.trim().isEmpty) {
      throw ArgumentError('Vehicle and location are required');
    }
    final now = DateTime.now();
    final price = basePrice ?? mockBasePrice(serviceType);
    final sequence = (++_sequence).toString().padLeft(3, '0');
    final order = RescueOrder(
      id: 'order-${now.microsecondsSinceEpoch}-$sequence',
      orderCode:
          'MC-${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-$sequence',
      status: RescueOrderStatus.pending,
      serviceType: serviceType,
      userVehicle: userVehicle.trim(),
      locationAddress: locationAddress.trim(),
      locationLandmark: locationLandmark.trim(),
      incidentDescription: incidentDescription.trim(),
      serviceOption: serviceOption.trim(),
      vehicleType: vehicleType.trim(),
      incidentPhotoBytes: incidentPhotoBytes == null
          ? null
          : Uint8List.fromList(incidentPhotoBytes).asUnmodifiableView(),
      basePrice: price,
      travelFee: travelFee ?? (price < 30000 ? price : 30000),
      extraPartPrice: 0,
      discount: discount,
      partnerId: partnerId,
      partnerName: partnerName,
      paymentMethod: paymentMethod,
      voucherCode: voucherCode,
      items: items,
      createdAt: now,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
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
