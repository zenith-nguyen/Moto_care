import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moto_care/features/activity/data/mock_rescue_orders.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';
import 'package:moto_care/features/activity/providers/activity_provider.dart';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('Cancellation moves only the selected active order into history', () {
    final container = _container();
    final controller = container.read(activityProvider.notifier);
    expect(controller.cancelOrder('active-001'), isTrue);
    final state = container.read(activityProvider);
    expect(state.activeOrders, isEmpty);
    expect(state.historyOrders.first.id, 'active-001');
    expect(state.orderById('active-001')!.status, RescueOrderStatus.cancelled);
    expect(state.orderById('completed-001')!.rating, 4.5);
    expect(mockRescueOrders.first.status, RescueOrderStatus.enRoute);
    expect(controller.cancelOrder('active-001'), isFalse);
    expect(controller.cancelOrder('completed-001'), isFalse);
    expect(controller.cancelOrder('unknown'), isFalse);
  });

  test(
    'Rebooking rejects duplicate requests and creates a fresh pending order',
    () {
      final container = _container();
      final controller = container.read(activityProvider.notifier);
      expect(
        () => controller.rebookOrder(
          'completed-001',
          userVehicle: 'Xe mới',
          locationAddress: 'Địa chỉ mới',
        ),
        throwsStateError,
      );
      controller.cancelOrder('active-001');
      final order = controller.rebookOrder(
        'completed-001',
        userVehicle: '  Honda Vision • 59-X2 222.22  ',
        locationAddress: '  20 Nguyễn Huệ, TP. Hồ Chí Minh  ',
      );
      expect(order.status, RescueOrderStatus.pending);
      expect(order.id, isNot('completed-001'));
      expect(order.userVehicle, 'Honda Vision • 59-X2 222.22');
      expect(order.locationAddress, '20 Nguyễn Huệ, TP. Hồ Chí Minh');
      expect(order.providerName, isNull);
      expect(order.providerPhone, isNull);
      expect(order.providerPlate, isNull);
      expect(order.rating, isNull);
      expect(order.providerDistanceKm, isNull);
      expect(order.etaMinutes, isNull);
      expect(order.extraPartPrice, 0);
      expect(order.discount, 0);
      expect(order.totalPrice, 110000);
      expect(
        container.read(activityProvider).orderById('completed-001')!.totalPrice,
        150000,
      );
    },
  );

  test(
    'Rebooking a cancelled order uses a new estimate and requires a location',
    () {
      final container = _container();
      final controller = container.read(activityProvider.notifier);
      controller.cancelOrder('active-001');
      expect(
        () => controller.rebookOrder(
          'cancelled-001',
          userVehicle: 'Honda Wave',
          locationAddress: '  ',
        ),
        throwsArgumentError,
      );
      final order = controller.rebookOrder(
        'cancelled-001',
        userVehicle: 'Honda Wave',
        locationAddress: '20 Nguyễn Huệ',
      );
      expect(order.totalPrice, 150000);
      expect(order.serviceType, RescueServiceType.engineFailure);
    },
  );

  test('Ratings are restricted to completed orders and valid stars', () {
    final container = _container();
    final controller = container.read(activityProvider.notifier);
    expect(controller.rateOrder('active-001', 5), isFalse);
    expect(controller.rateOrder('cancelled-001', 5), isFalse);
    expect(controller.rateOrder('completed-001', 0), isFalse);
    expect(controller.rateOrder('completed-001', 6), isFalse);
    expect(controller.rateOrder('completed-001', 5), isTrue);
    expect(
      container.read(activityProvider).orderById('completed-001')!.rating,
      5,
    );
  });

  test('Complaints retain order identity and shared state is immutable', () {
    final container = _container();
    final controller = container.read(activityProvider.notifier);
    expect(
      controller.reportOrder('unknown', 'Nội dung khiếu nại hợp lệ'),
      isFalse,
    );
    expect(controller.reportOrder('completed-001', 'ngắn'), isFalse);
    expect(
      controller.reportOrder(
        'completed-001',
        '  Chi phí phụ tùng chưa rõ ràng.  ',
      ),
      isTrue,
    );
    final state = container.read(activityProvider);
    expect(state.complaints.single.orderId, 'completed-001');
    expect(state.complaints.single.message, 'Chi phí phụ tùng chưa rõ ràng.');
    expect(() => state.orders.clear(), throwsUnsupportedError);
    expect(() => state.complaints.clear(), throwsUnsupportedError);
  });
}
