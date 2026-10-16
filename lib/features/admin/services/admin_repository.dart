import '../models/admin_models.dart';

/// API contract. Replace the injected mock with an authenticated Dio adapter.
abstract class AdminRepository {
  /// GET /admin/dashboard/summary?from=...&to=...
  Future<AdminDashboardSummary> dashboardSummary(AdminDateRange range);

  /// GET /admin/dashboard/timeseries?from=...&to=...
  Future<List<AdminTimeseriesPoint>> dashboardTimeseries(AdminDateRange range);

  /// GET /admin/orders; filters are client-side in the session mock.
  Future<List<AdminOrder>> orders();

  /// GET /admin/providers/pending
  Future<List<AdminProviderApplication>> pendingProviders();

  /// PATCH /admin/providers/:providerId/approval
  Future<void> resolveProvider(
    String id, {
    required bool approve,
    required String note,
  });

  /// GET /admin/reconciliation
  Future<List<AdminReconciliation>> reconciliation();

  /// GET /admin/refunds/pending
  Future<List<AdminRefund>> pendingRefunds();

  /// GET /admin/payment-adjustments/pending-refunds
  Future<List<AdminRefund>> pendingAdjustmentRefunds();

  /// GET /admin/price-disputes/pending
  Future<List<AdminPriceDispute>> pendingDisputes();

  /// PATCH /admin/price-disputes/:proposalId/resolve
  Future<void> resolveDispute(
    String id, {
    required bool approve,
    required String note,
  });

  /// GET /admin/withdrawals/pending
  Future<List<AdminWithdrawal>> pendingWithdrawals();

  /// PATCH /admin/withdrawals/:requestId/resolve
  Future<void> resolveWithdrawal(
    String id, {
    required bool approve,
    required String note,
  });

  /// Integration seam for wallet history; no backend endpoint assumed yet.
  Future<AdminWallet> wallet(String providerId);
}
