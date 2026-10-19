import 'package:flutter_test/flutter_test.dart';
import 'package:revo/features/activity/data/mock_rescue_orders.dart';
import 'package:revo/features/activity/models/order_cancellation_reason.dart';
import 'package:revo/features/activity/models/rescue_order.dart';

void main() {
  test('Only known quick reasons or nonblank custom details are accepted', () {
    expect(OrderCancellationReason.tryCreate(), isNull);
    expect(OrderCancellationReason.tryCreate(details: ' \n '), isNull);
    expect(OrderCancellationReason.tryCreate(selectedReason: 'other'), isNull);
    expect(
      OrderCancellationReason.tryCreate(
        selectedReason: 'unknown',
        details: 'Note',
      ),
      isNull,
    );
    final quick = OrderCancellationReason.tryCreate(
      selectedReason: 'long_wait',
    )!;
    expect(quick.code, 'long_wait');
    expect(quick.details, isEmpty);
    final custom = OrderCancellationReason.tryCreate(
      details: '  Xe đã sửa xong  ',
    )!;
    expect(custom.code, 'other');
    expect(custom.description, 'Xe đã sửa xong');
    expect(
      () => OrderCancellationReason.fromJson({'code': 'other', 'details': ' '}),
      throwsFormatException,
    );
  });

  test(
    'Order JSON and copyWith preserve reasons; legacy records remain readable',
    () {
      final legacy = mockRescueOrders.first.toJson()
        ..remove('cancellationReason');
      expect(RescueOrder.fromJson(legacy).cancellationReason, isNull);
      final reason = OrderCancellationReason.tryCreate(
        selectedReason: 'resolved_elsewhere',
        details: '  Tiệm gần nhà đã hỗ trợ  ',
      )!;
      final order = mockRescueOrders.first.copyWith(
        status: RescueOrderStatus.cancelled,
        cancellationReason: reason,
      );
      final restored = RescueOrder.fromJson(order.toJson()).copyWith(rating: 4);
      expect(restored.cancellationReason!.toJson(), {
        'code': 'resolved_elsewhere',
        'label': reason.label,
        'details': 'Tiệm gần nhà đã hỗ trợ',
      });
      expect(restored.toJson()['cancellationReason'], reason.toJson());
    },
  );
}
