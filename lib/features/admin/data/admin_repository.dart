import '../../../core/money/money_amount.dart';
import '../../../core/network/json_api.dart';
import '../../orders/domain/order_status.dart';
import '../../orders/domain/price_decision_result.dart';
import '../../payments/domain/demo_payment_result.dart';
import '../../wallet/domain/wallet_models.dart';
import '../domain/admin_analytics_models.dart';
import '../domain/admin_operation_models.dart';

abstract interface class AdminRepository {
  Future<AdminDashboardSummary> getDashboardSummary({
    DateTime? from,
    DateTime? to,
  });

  Future<AdminTimeseries> getDashboardTimeseries({
    DateTime? from,
    DateTime? to,
  });

  Future<AdminReconciliationPage> getReconciliation({
    DateTime? from,
    DateTime? to,
    PaymentStatus? status,
    int page = 1,
    int limit = 50,
  });

  Future<List<AdminRecentOrder>> listRecentOrders();

  Future<List<PendingProviderApplication>> listPendingProviders();

  Future<ProviderReviewResult> reviewProvider({
    required int providerId,
    required ProviderApprovalStatus status,
  });

  Future<List<PendingFullRefund>> listPendingFullRefunds();

  Future<DemoRefundResult> refundFullOrder(int orderId);

  Future<List<AdminPriceDispute>> listPendingPriceDisputes();

  Future<PriceDecisionResult> resolvePriceDispute({
    required int proposalId,
    required AdminDecision decision,
    required String reason,
  });

  Future<List<PendingRefundAdjustment>> listPendingRefundAdjustments();

  Future<DemoAdjustmentResult> refundAdjustment(int orderId);

  Future<List<AdminWithdrawal>> listPendingWithdrawals();

  Future<WithdrawalCreationResult> resolveWithdrawal({
    required int requestId,
    required AdminDecision decision,
    String? reason,
  });

  Future<List<AdminWithdrawalPayout>> listPendingWithdrawalPayouts();

  Future<AdminWithdrawalPayout> reconcileWithdrawalPayout({
    required int payoutId,
    required PayoutReconciliationDecision decision,
    String? externalTransactionId,
    String? referenceCode,
    String? observedAmount,
    String? reason,
  });
}

class HttpAdminRepository implements AdminRepository {
  const HttpAdminRepository(this._api);

  final JsonApi _api;

  @override
  Future<AdminDashboardSummary> getDashboardSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _api.getObject(
      '/admin/dashboard/summary',
      queryParameters: _periodQuery(from: from, to: to),
    );
    return AdminDashboardSummary.fromJson(response);
  }

  @override
  Future<AdminTimeseries> getDashboardTimeseries({
    DateTime? from,
    DateTime? to,
  }) async {
    final response = await _api.getObject(
      '/admin/dashboard/timeseries',
      queryParameters: {
        ..._periodQuery(from: from, to: to),
        'bucket': 'day',
      },
    );
    return AdminTimeseries.fromJson(response);
  }

  @override
  Future<AdminReconciliationPage> getReconciliation({
    DateTime? from,
    DateTime? to,
    PaymentStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 100.');
    }
    final response = await _api.getObject(
      '/admin/reconciliation',
      queryParameters: {
        ..._periodQuery(from: from, to: to),
        if (status != null) 'status': status.wireValue,
        'page': page,
        'limit': limit,
      },
    );
    return AdminReconciliationPage.fromJson(response);
  }

  @override
  Future<List<AdminRecentOrder>> listRecentOrders() async {
    final response = await _api.getList('/admin/orders');
    return response.map(AdminRecentOrder.fromJson).toList(growable: false);
  }

  @override
  Future<List<PendingProviderApplication>> listPendingProviders() async {
    final response = await _api.getList('/admin/providers/pending');
    return response
        .map(PendingProviderApplication.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ProviderReviewResult> reviewProvider({
    required int providerId,
    required ProviderApprovalStatus status,
  }) async {
    _requirePositiveId(providerId, 'providerId');
    if (status == ProviderApprovalStatus.pending) {
      throw ArgumentError.value(status, 'status', 'Must be a final decision.');
    }
    final response = await _api.patchObject(
      '/admin/providers/$providerId/approval',
      data: {'status': status.wireValue},
    );
    return ProviderReviewResult.fromJson(response);
  }

  @override
  Future<List<PendingFullRefund>> listPendingFullRefunds() async {
    final response = await _api.getList('/admin/refunds/pending');
    return response.map(PendingFullRefund.fromJson).toList(growable: false);
  }

  @override
  Future<DemoRefundResult> refundFullOrder(int orderId) async {
    _requirePositiveId(orderId, 'orderId');
    final response = await _api.postObject(
      '/payments/demo/orders/$orderId/refund',
    );
    return DemoRefundResult.fromJson(response);
  }

  @override
  Future<List<AdminPriceDispute>> listPendingPriceDisputes() async {
    final response = await _api.getList('/admin/price-disputes/pending');
    return response.map(AdminPriceDispute.fromJson).toList(growable: false);
  }

  @override
  Future<PriceDecisionResult> resolvePriceDispute({
    required int proposalId,
    required AdminDecision decision,
    required String reason,
  }) async {
    _requirePositiveId(proposalId, 'proposalId');
    final normalizedReason = _requireReason(reason, minLength: 5);
    final response = await _api.patchObject(
      '/admin/price-disputes/$proposalId/resolve',
      data: {'decision': decision.wireValue, 'reason': normalizedReason},
    );
    return PriceDecisionResult.fromJson(response);
  }

  @override
  Future<List<PendingRefundAdjustment>> listPendingRefundAdjustments() async {
    final response = await _api.getList(
      '/admin/payment-adjustments/pending-refunds',
    );
    return response
        .map(PendingRefundAdjustment.fromJson)
        .toList(growable: false);
  }

  @override
  Future<DemoAdjustmentResult> refundAdjustment(int orderId) async {
    _requirePositiveId(orderId, 'orderId');
    final response = await _api.postObject(
      '/payments/demo/orders/$orderId/adjustment/refund',
    );
    return DemoAdjustmentResult.fromJson(response);
  }

  @override
  Future<List<AdminWithdrawal>> listPendingWithdrawals() async {
    final response = await _api.getList('/admin/withdrawals/pending');
    return response.map(AdminWithdrawal.fromJson).toList(growable: false);
  }

  @override
  Future<WithdrawalCreationResult> resolveWithdrawal({
    required int requestId,
    required AdminDecision decision,
    String? reason,
  }) async {
    _requirePositiveId(requestId, 'requestId');
    final normalizedReason = reason?.trim();
    if (decision == AdminDecision.reject) {
      _requireReason(normalizedReason ?? '', minLength: 3);
    } else if (normalizedReason != null && normalizedReason.isNotEmpty) {
      _requireReason(normalizedReason, minLength: 3);
    }
    final response = await _api.patchObject(
      '/admin/withdrawals/$requestId/resolve',
      data: {
        'decision': decision.wireValue,
        if (normalizedReason != null && normalizedReason.isNotEmpty)
          'reason': normalizedReason,
      },
    );
    return WithdrawalCreationResult.fromJson(response);
  }

  @override
  Future<List<AdminWithdrawalPayout>> listPendingWithdrawalPayouts() async {
    final response = await _api.getList('/admin/withdrawal-payouts/pending');
    return response.map(AdminWithdrawalPayout.fromJson).toList(growable: false);
  }

  @override
  Future<AdminWithdrawalPayout> reconcileWithdrawalPayout({
    required int payoutId,
    required PayoutReconciliationDecision decision,
    String? externalTransactionId,
    String? referenceCode,
    String? observedAmount,
    String? reason,
  }) async {
    _requirePositiveId(payoutId, 'payoutId');
    final data = <String, dynamic>{'decision': decision.wireValue};
    if (decision == PayoutReconciliationDecision.confirm) {
      final transactionId = (externalTransactionId ?? '').trim();
      if (transactionId.length < 3 || transactionId.length > 120) {
        throw ArgumentError.value(
          externalTransactionId,
          'externalTransactionId',
          'Must contain 3-120 characters.',
        );
      }
      if (observedAmount == null) {
        throw ArgumentError.notNull('observedAmount');
      }
      // Validates the two-decimal money format before it reaches the backend.
      final amount = MoneyAmount.parse(observedAmount);
      data['externalTransactionId'] = transactionId;
      data['observedAmount'] = amount.value;
      final normalizedReference = referenceCode?.trim();
      if (normalizedReference != null && normalizedReference.isNotEmpty) {
        if (normalizedReference.length > 120) {
          throw ArgumentError.value(
            referenceCode,
            'referenceCode',
            'Must be at most 120 characters.',
          );
        }
        data['referenceCode'] = normalizedReference;
      }
      final normalizedReason = reason?.trim();
      if (normalizedReason != null && normalizedReason.isNotEmpty) {
        data['reason'] = _requireReason(normalizedReason, minLength: 3);
      }
    } else {
      data['reason'] = _requireReason(reason ?? '', minLength: 3);
    }
    final response = await _api.patchObject(
      '/admin/withdrawal-payouts/$payoutId/reconcile',
      data: data,
    );
    return AdminWithdrawalPayout.fromJson(response);
  }
}

Map<String, dynamic> _periodQuery({DateTime? from, DateTime? to}) {
  if ((from == null) != (to == null)) {
    throw ArgumentError('from and to must be provided together.');
  }
  if (from == null || to == null) return const {};
  final normalizedFrom = from.toUtc();
  final normalizedTo = to.toUtc();
  if (!normalizedFrom.isBefore(normalizedTo)) {
    throw ArgumentError('from must be earlier than to.');
  }
  if (normalizedTo.difference(normalizedFrom) > const Duration(days: 366)) {
    throw ArgumentError('Reporting period cannot exceed 366 days.');
  }
  return {
    'from': normalizedFrom.toIso8601String(),
    'to': normalizedTo.toIso8601String(),
  };
}

String _requireReason(String value, {required int minLength}) {
  final normalized = value.trim();
  if (normalized.length < minLength || normalized.length > 500) {
    throw ArgumentError.value(
      value,
      'reason',
      'Must contain $minLength-500 characters.',
    );
  }
  return normalized;
}

void _requirePositiveId(int value, String name) {
  if (value <= 0) throw ArgumentError.value(value, name);
}
