import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/orders/domain/order_status.dart';
import 'package:moto_care/features/payments/data/payments_repository.dart';

import '../../support/recording_json_api.dart';

void main() {
  late RecordingJsonApi api;
  late HttpPaymentsRepository repository;

  setUp(() {
    api = RecordingJsonApi();
    repository = HttpPaymentsRepository(api);
  });

  test('confirms demo prepayment through the exact sandbox endpoint', () async {
    api.objectResponse = {
      'orderId': 42,
      'status': 'PENDING_MATCH',
      'paymentStatus': 'PAID',
      'matched': true,
    };

    final result = await repository.confirmDemoPrepayment(42);

    expect(api.lastMethod, 'POST');
    expect(api.lastPath, '/payments/demo/orders/42/confirm');
    expect(api.lastData, isNull);
    expect(result.orderId, 42);
    expect(result.orderStatus, OrderStatus.pendingMatch);
    expect(result.paymentStatus, PaymentStatus.paid);
    expect(result.matched, isTrue);
  });

  test(
    'parses a demo payment adjustment without using floating money',
    () async {
      api.objectResponse = {
        'orderId': 42,
        'status': 'PAID',
        'paymentAdjustment': {
          'id': 9,
          'type': 'CHARGE',
          'amount': '25000.00',
          'status': 'SETTLED',
          'isDemo': true,
          'settledAt': '2026-10-09T09:30:00.000Z',
        },
      };

      final result = await repository.confirmDemoAdjustment(42);

      expect(api.lastPath, '/payments/demo/orders/42/adjustment/confirm');
      expect(result.orderStatus, OrderStatus.paid);
      expect(result.adjustment.type, PaymentAdjustmentType.charge);
      expect(result.adjustment.amount.value, '25000.00');
      expect(result.adjustment.status, PaymentAdjustmentStatus.settled);
    },
  );

  test('rejects invalid order IDs before making a request', () async {
    await expectLater(repository.confirmDemoPrepayment(0), throwsArgumentError);

    expect(api.lastPath, isNull);
  });
}
