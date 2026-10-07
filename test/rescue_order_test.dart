import 'package:flutter_test/flutter_test.dart';

import 'package:moto_care/features/activity/data/mock_rescue_orders.dart';
import 'package:moto_care/features/activity/models/rescue_order.dart';

void main() {
  test(
    'Legacy orders load without notes and updates retain new incident details',
    () {
      final legacy = mockRescueOrders.first.toJson()
        ..remove('locationLandmark')
        ..remove('incidentDescription');
      final original = RescueOrder.fromJson(legacy);
      expect(original.locationLandmark, isEmpty);
      expect(original.incidentDescription, isEmpty);
      final saved = RescueOrder.fromJson({
        ...legacy,
        'locationLandmark': 'Cổng trường bên phải',
        'incidentDescription': 'Xe không đề được',
      });
      final updated = saved.copyWith(status: RescueOrderStatus.repairing);
      expect(updated.locationLandmark, saved.locationLandmark);
      expect(updated.incidentDescription, saved.incidentDescription);
      expect(RescueOrder.fromJson(updated.toJson()).toJson(), updated.toJson());
    },
  );

  test(
    'Invoice total includes travel, labor, parts and voucher exactly once',
    () {
      final order = mockRescueOrders[1];
      expect(order.travelFee, 30000);
      expect(order.laborFee, 80000);
      expect(order.basePrice, order.travelFee + order.laborFee);
      expect(order.totalPrice, 150000);
      expect(
        order.totalPrice,
        order.travelFee +
            order.laborFee +
            order.extraPartPrice -
            order.discount,
      );
    },
  );

  test(
    'JSON round trips prices, wire statuses, optional provider and rating',
    () {
      for (final order in mockRescueOrders) {
        expect(RescueOrder.fromJson(order.toJson()).toJson(), order.toJson());
      }
      expect(mockRescueOrders.first.toJson()['status'], 'en_route');
      expect(mockRescueOrders.last.toJson()['status'], 'cancelled');
      expect(mockRescueOrders.last.providerName, isNull);
    },
  );

  test(
    'Unknown wire values are rejected instead of silently becoming active',
    () {
      final json = mockRescueOrders.first.toJson();
      expect(
        () => RescueOrder.fromJson({...json, 'status': 'invalid'}),
        throwsFormatException,
      );
      expect(
        () => RescueOrder.fromJson({...json, 'serviceType': 'invalid'}),
        throwsFormatException,
      );
    },
  );

  test('Invalid charges, vouchers and ratings cannot enter the model', () {
    final json = mockRescueOrders.first.toJson();
    for (final values in [
      {'basePrice': -1},
      {'extraPartPrice': -1},
      {'discount': -1},
      {'discount': 999999},
      {'travelFee': 999999},
      {'rating': 6},
      {'rating': double.nan},
      {'providerDistanceKm': -1},
      {'etaMinutes': -1},
    ]) {
      expect(
        () => RescueOrder.fromJson({...json, ...values}),
        throwsArgumentError,
      );
    }
  });

  test('Active status maps to the correct progress step', () {
    final order = mockRescueOrders.first;
    expect(order.progressStep, 2);
    expect(order.copyWith(status: RescueOrderStatus.repairing).progressStep, 3);
    expect(order.copyWith(status: RescueOrderStatus.pending).progressStep, 1);
    final unassigned = RescueOrder.fromJson({
      ...order.toJson(),
      'status': 'pending',
      'providerName': null,
    });
    expect(unassigned.progressStep, 0);
    for (final status in RescueOrderStatus.values) {
      expect(
        status.isActive,
        ['pending', 'en_route', 'repairing'].contains(status.value),
      );
    }
  });
}
