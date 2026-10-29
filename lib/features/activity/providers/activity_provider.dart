import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_rescue_orders.dart';
import '../data/activity_api_orders.dart';
import '../../../app/app_dependencies.dart';
import '../../orders/domain/geo_point.dart';
import '../models/order_cancellation_reason.dart';
import '../models/rescue_order.dart';
import '../models/activity_state.dart';
export '../models/activity_state.dart';
import '../models/activity_filter.dart';
import '../services/rescue_order_service.dart';
import '../../profile/providers/profile_provider.dart';

final initialRescueOrdersProvider = Provider<List<RescueOrder>>(
  (ref) => mockRescueOrders,
);

final activityProvider = NotifierProvider<ActivityController, ActivityState>(
  ActivityController.new,
);

final incidentBasePriceProvider =
    FutureProvider.family<int?, RescueServiceType>((ref, serviceType) async {
      if (!ref.watch(runtimeApiIntegrationProvider)) {
        return mockBasePrice(serviceType);
      }
      final code = _incidentCode(serviceType);
      if (code == null) return null;
      final incidents = await ref
          .watch(incidentTypesRepositoryProvider)
          .listActive();
      final matches = incidents.where((item) => item.code == code);
      if (matches.isEmpty) return null;
      return double.parse(matches.first.basePrice.value).round();
    });

String? _incidentCode(RescueServiceType serviceType) => switch (serviceType) {
  RescueServiceType.flatTire => 'FLAT_TIRE',
  RescueServiceType.outOfFuel => 'OUT_OF_FUEL',
  RescueServiceType.engineFailure => 'ENGINE_FAILURE',
  RescueServiceType.batteryJump => 'DEAD_BATTERY',
  _ => null,
};

class ActivityController extends Notifier<ActivityState> {
  @override
  ActivityState build() {
    final initial = ref.watch(initialRescueOrdersProvider);
    if (!ref.watch(runtimeApiIntegrationProvider)) {
      return ActivityState(orders: initial);
    }
    // Do not fire this listener while the Notifier is still inside build().
    // With Riverpod 3, fireImmediately can invoke the callback before `state`
    // has been initialized, which makes the customer app throw while opening
    // Home/Activity. The initial loading state below covers that first frame;
    // subsequent API updates still arrive through this listener.
    ref.listen(activityApiOrdersProvider, (_, next) {
      next.when(
        data: (orders) =>
            state = ActivityState(orders: orders, complaints: state.complaints),
        error: (error, _) => state = ActivityState(
          orders: state.orders,
          complaints: state.complaints,
          failure: error,
        ),
        loading: () => state = ActivityState(
          orders: state.orders,
          complaints: state.complaints,
          loading: true,
        ),
      );
    }, fireImmediately: false);
    return ActivityState(orders: const [], loading: true);
  }

  void refreshFromApi() => ref.invalidate(activityApiOrdersProvider);

  Future<RescueOrder> createOrderFromApi({
    required RescueServiceType serviceType,
    required String userVehicle,
    required String locationAddress,
    required double? locationLatitude,
    required double? locationLongitude,
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
  }) async {
    if (!ref.read(runtimeApiIntegrationProvider)) {
      return createOrder(
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
    }
    if (locationLatitude == null || locationLongitude == null) {
      throw StateError(
        'Vui lòng chọn vị trí GPS trên bản đồ trước khi đặt cứu hộ.',
      );
    }
    final code = _incidentCode(serviceType);
    if (code == null) {
      throw StateError('Dịch vụ này chưa được backend hỗ trợ đặt trực tuyến.');
    }
    final incidents = await ref
        .read(incidentTypesRepositoryProvider)
        .listActive();
    final matches = incidents.where((item) => item.code == code);
    final incident = matches.isEmpty ? null : matches.first;
    if (incident == null) throw StateError('Loại sự cố hiện không khả dụng.');
    final created = await ref
        .read(ordersRepositoryProvider)
        .create(
          incidentTypeId: incident.id,
          customerLocation: GeoPoint(
            latitude: locationLatitude,
            longitude: locationLongitude,
          ),
        );
    // Best-effort: attach the incident photo so the mechanic can see it. The
    // order already exists, so a failed upload must not fail order creation.
    if (incidentPhotoBytes != null && incidentPhotoBytes.isNotEmpty) {
      try {
        await ref
            .read(orderPhotosRepositoryProvider)
            .upload(orderId: created.id, bytes: incidentPhotoBytes);
      } catch (_) {
        // Swallow: the order stands even if the photo could not be stored.
      }
    }
    ref.invalidate(activityApiOrdersProvider);
    final orders = await ref.read(activityApiOrdersProvider.future);
    return orders.firstWhere((order) => order.id == created.id.toString());
  }

  Future<bool> cancelOrderFromApi(
    String id, {
    OrderCancellationReason? reason,
  }) async {
    if (!ref.read(runtimeApiIntegrationProvider)) {
      return cancelOrder(id, reason: reason);
    }
    final orderId = int.tryParse(id);
    if (orderId == null) return false;
    try {
      await ref
          .read(ordersRepositoryProvider)
          .cancel(orderId, reason?.description ?? 'Khách hàng yêu cầu hủy');
      ref.invalidate(activityApiOrdersProvider);
      await ref.read(activityApiOrdersProvider.future);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool cancelOrder(String id, {OrderCancellationReason? reason}) {
    final order = state.orderById(id);
    if (order == null || !order.status.isActive) return false;
    _replaceOrder(
      order.copyWith(
        status: RescueOrderStatus.cancelled,
        cancellationReason: reason,
        statusEvents: [
          ...order.statusEvents,
          RescueOrderEvent(
            status: RescueOrderStatus.cancelled,
            occurredAt: ref.read(rescueOrderClockProvider)(),
            description: reason?.description ?? '',
          ),
        ],
      ),
    );
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
    final requester = ref.read(profileProvider).profile;
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
          requesterName: requester.fullName,
          requesterPhone: requester.phoneNumber,
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
