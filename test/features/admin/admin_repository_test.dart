import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/features/admin/data/admin_repository.dart';
import 'package:moto_care/features/admin/domain/admin_analytics_models.dart';
import 'package:moto_care/features/admin/domain/admin_operation_models.dart';
import 'package:moto_care/features/orders/domain/order_status.dart';

import '../../support/recording_json_api.dart';

void main() {
  test('loads dashboard summary using an explicit UTC period', () async {
    final api = RecordingJsonApi()..objectResponse = _summaryJson();
    final repository = HttpAdminRepository(api);

    final summary = await repository.getDashboardSummary(
      from: DateTime.parse('2026-10-01T07:00:00+07:00'),
      to: DateTime.parse('2026-10-08T07:00:00+07:00'),
    );

    expect(api.lastPath, '/admin/dashboard/summary');
    expect(api.lastQueryParameters, {
      'from': '2026-10-01T00:00:00.000Z',
      'to': '2026-10-08T00:00:00.000Z',
    });
    expect(summary.money.collectedInPeriod.value, '450000.00');
    expect(summary.orders.byStatus[OrderStatus.completed], 2);
    expect(summary.sandboxOnly, isTrue);
  });

  test('loads daily timeseries and preserves decimal money', () async {
    final api = RecordingJsonApi()..objectResponse = _timeseriesJson();

    final result = await HttpAdminRepository(api).getDashboardTimeseries();

    expect(api.lastQueryParameters, {'bucket': 'day'});
    expect(result.data.single.day, '2026-10-10');
    expect(result.data.single.refunded.value, '100000.00');
  });

  test('loads filtered reconciliation page and anomaly flags', () async {
    final api = RecordingJsonApi()..objectResponse = _reconciliationJson();

    final result = await HttpAdminRepository(api)
        .getReconciliation(status: PaymentStatus.paid, page: 2, limit: 10);

    expect(api.lastPath, '/admin/reconciliation');
    expect(api.lastQueryParameters, {'status': 'PAID', 'page': 2, 'limit': 10});
    expect(result.items.single.flags, [
      ReconciliationFlag.paymentFinalPriceMismatch,
    ]);
    expect(result.items.single.order.provider?.name, 'Tho mot');
  });

  test(
    'sends provider and dispute decisions with exact wire payloads',
    () async {
      final api = RecordingJsonApi()
        ..objectResponse = {
          'id': 3,
          'userId': 8,
          'approvalStatus': 'APPROVED',
          'accountStatus': 'ACTIVE',
        };
      final repository = HttpAdminRepository(api);

      final provider = await repository.reviewProvider(
        providerId: 3,
        status: ProviderApprovalStatus.approved,
      );
      expect(api.lastPath, '/admin/providers/3/approval');
      expect(api.lastData, {'status': 'APPROVED'});
      expect(provider.approvalStatus, ProviderApprovalStatus.approved);

      api.objectResponse = _priceDecisionJson();
      await repository.resolvePriceDispute(
        proposalId: 12,
        decision: AdminDecision.reject,
        reason: '  Khong du chung tu  ',
      );
      expect(api.lastPath, '/admin/price-disputes/12/resolve');
      expect(api.lastData, {
        'decision': 'REJECT',
        'reason': 'Khong du chung tu',
      });
    },
  );

  test('does not allow unsafe or incomplete financial decisions', () async {
    final repository = HttpAdminRepository(RecordingJsonApi());

    expect(
      () => repository.reviewProvider(
        providerId: 3,
        status: ProviderApprovalStatus.pending,
      ),
      throwsArgumentError,
    );
    expect(
      () => repository.resolveWithdrawal(
        requestId: 4,
        decision: AdminDecision.reject,
      ),
      throwsArgumentError,
    );
    expect(() => repository.getReconciliation(page: 0), throwsArgumentError);
  });

  test('parses pending withdrawal with provider identity', () async {
    final api = RecordingJsonApi()..listResponse = [_withdrawalJson()];

    final requests = await HttpAdminRepository(api).listPendingWithdrawals();

    expect(api.lastPath, '/admin/withdrawals/pending');
    expect(requests.single.request.amount.value, '75000.00');
    expect(requests.single.provider.name, 'Tho mot');
  });
}

Map<String, dynamic> _periodJson() => {
  'from': '2026-10-01T00:00:00.000Z',
  'to': '2026-10-08T00:00:00.000Z',
  'timezone': 'Asia/Ho_Chi_Minh',
};

Map<String, dynamic> _summaryJson() => {
  'period': _periodJson(),
  'generatedAt': '2026-10-08T00:00:01.000Z',
  'sandboxOnly': true,
  'users': {
    'total': 10,
    'customers': 6,
    'providers': 3,
    'admins': 1,
    'createdInPeriod': 2,
  },
  'providers': {
    'total': 3,
    'pending': 1,
    'approved': 2,
    'rejected': 0,
    'online': 1,
    'freshLocation': 1,
  },
  'orders': {
    'total': 4,
    'byStatus': {for (final status in OrderStatus.values) status.wireValue: 0}
      ..['COMPLETED'] = 2,
    'completionRate': 50.0,
  },
  'money': {
    'collectedInPeriod': '450000.00',
    'heldCurrent': '100000.00',
    'settledToProvidersInPeriod': '300000.00',
    'refundPendingCurrent': '50000.00',
    'refundedInPeriod': '100000.00',
    'grossCompletedValueInPeriod': '400000.00',
    'providerWalletBalanceCurrent': '300000.00',
    'providerWalletLockedCurrent': '75000.00',
    'providerWalletAvailableCurrent': '225000.00',
    'pendingWithdrawalAmountCurrent': '75000.00',
    'providerWithdrawnInPeriod': '50000.00',
  },
};

Map<String, dynamic> _timeseriesJson() => {
  'period': _periodJson(),
  'bucket': 'day',
  'sandboxOnly': true,
  'data': [
    {
      'day': '2026-10-10',
      'ordersCreated': 3,
      'ordersCompleted': 2,
      'collected': '450000.00',
      'settledToProviders': '300000.00',
      'refunded': '100000.00',
      'providerWithdrawn': '50000.00',
    },
  ],
};

Map<String, dynamic> _reconciliationJson() => {
  'period': _periodJson(),
  'sandboxOnly': true,
  'page': 2,
  'limit': 10,
  'total': 11,
  'totalPages': 2,
  'items': [
    {
      'order': {
        'id': 42,
        'code': 'MC-42',
        'status': 'COMPLETED',
        'createdAt': '2026-10-10T08:00:00.000Z',
        'finalPrice': '120000.00',
        'customer': {'id': 7, 'name': 'Khach mot'},
        'provider': {'id': 3, 'name': 'Tho mot'},
      },
      'payment': {
        'id': 5,
        'status': 'PAID',
        'amount': '100000.00',
        'paidAt': '2026-10-10T08:01:00.000Z',
        'refundedAt': null,
        'isDemo': true,
        'paymentCount': 1,
      },
      'settlement': {
        'creditCount': 1,
        'creditedAmount': '120000.00',
        'adjustment': null,
      },
      'flags': ['PAYMENT_FINAL_PRICE_MISMATCH'],
    },
  ],
};

Map<String, dynamic> _priceDecisionJson() => {
  'orderId': 42,
  'orderStatus': 'AWAITING_PAYMENT',
  'proposal': {
    'id': 12,
    'proposedFinalPrice': '120000.00',
    'reason': 'Them vat tu',
    'status': 'RESOLVED_REJECTED',
    'customerReason': null,
    'disputeReason': 'Khong dong y',
    'resolutionReason': 'Khong du chung tu',
  },
  'paymentAdjustment': null,
};

Map<String, dynamic> _withdrawalJson() => {
  'id': 4,
  'providerId': 3,
  'amount': '75000.00',
  'status': 'PENDING',
  'decisionReason': null,
  'processedById': null,
  'processedAt': null,
  'createdAt': '2026-10-10T08:00:00.000Z',
  'updatedAt': '2026-10-10T08:00:00.000Z',
  'provider': {'id': 3, 'userId': 8, 'name': 'Tho mot'},
};
