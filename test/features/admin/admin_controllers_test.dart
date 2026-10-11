import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/core/money/money_amount.dart';
import 'package:moto_care/features/admin/application/admin_dashboard_controller.dart';
import 'package:moto_care/features/admin/application/admin_operations_controller.dart';
import 'package:moto_care/features/admin/data/admin_repository.dart';
import 'package:moto_care/features/admin/domain/admin_analytics_models.dart';
import 'package:moto_care/features/admin/domain/admin_operation_models.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/orders/domain/order_status.dart';
import 'package:moto_care/features/orders/domain/price_decision_result.dart';
import 'package:moto_care/features/payments/domain/demo_payment_result.dart';
import 'package:moto_care/features/wallet/domain/wallet_models.dart';

void main() {
  test('dashboard changes reconciliation filter through repository', () async {
    final repository = FakeAdminRepository();
    final container = ProviderContainer(
      overrides: [adminRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final initial = await container.read(
      adminDashboardControllerProvider.future,
    );
    expect(initial.summary.users.total, 10);

    await container
        .read(adminDashboardControllerProvider.notifier)
        .changeReconciliation(paymentStatus: PaymentStatus.refundPending);

    final filtered = container.read(adminDashboardControllerProvider).value!;
    expect(filtered.paymentFilter, PaymentStatus.refundPending);
    expect(repository.lastPaymentStatus, PaymentStatus.refundPending);
    expect(repository.reconciliationLoads, 2);
  });

  test(
    'provider approval refreshes only the affected operations queue',
    () async {
      final repository = FakeAdminRepository();
      final container = ProviderContainer(
        overrides: [adminRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(
        adminOperationsControllerProvider.future,
      );
      expect(initial.pendingProviders.single.id, 3);

      await container
          .read(adminOperationsControllerProvider.notifier)
          .reviewProvider(
            providerId: 3,
            status: ProviderApprovalStatus.approved,
          );

      final reviewed = container.read(adminOperationsControllerProvider).value!;
      expect(repository.reviewCount, 1);
      expect(reviewed.pendingProviders, isEmpty);
      expect(reviewed.isBusy, isFalse);
      expect(reviewed.lastFailure, isNull);
    },
  );
}

class FakeAdminRepository implements AdminRepository {
  int reconciliationLoads = 0;
  int reviewCount = 0;
  PaymentStatus? lastPaymentStatus;
  var _providerPending = true;

  @override
  Future<AdminDashboardSummary> getDashboardSummary({
    DateTime? from,
    DateTime? to,
  }) async => _summary;

  @override
  Future<AdminTimeseries> getDashboardTimeseries({
    DateTime? from,
    DateTime? to,
  }) async => _timeseries;

  @override
  Future<AdminReconciliationPage> getReconciliation({
    DateTime? from,
    DateTime? to,
    PaymentStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    reconciliationLoads += 1;
    lastPaymentStatus = status;
    return _reconciliation;
  }

  @override
  Future<List<AdminRecentOrder>> listRecentOrders() async => const [];

  @override
  Future<List<PendingProviderApplication>> listPendingProviders() async {
    return _providerPending ? [_pendingProvider] : const [];
  }

  @override
  Future<ProviderReviewResult> reviewProvider({
    required int providerId,
    required ProviderApprovalStatus status,
  }) async {
    reviewCount += 1;
    _providerPending = false;
    return const ProviderReviewResult(
      id: 3,
      userId: 8,
      approvalStatus: ProviderApprovalStatus.approved,
      accountStatus: AppUserStatus.active,
    );
  }

  @override
  Future<List<PendingFullRefund>> listPendingFullRefunds() async => const [];

  @override
  Future<List<AdminPriceDispute>> listPendingPriceDisputes() async => const [];

  @override
  Future<List<PendingRefundAdjustment>> listPendingRefundAdjustments() async =>
      const [];

  @override
  Future<List<AdminWithdrawal>> listPendingWithdrawals() async => const [];

  @override
  Future<DemoAdjustmentResult> refundAdjustment(int orderId) =>
      throw UnimplementedError();

  @override
  Future<DemoRefundResult> refundFullOrder(int orderId) =>
      throw UnimplementedError();

  @override
  Future<PriceDecisionResult> resolvePriceDispute({
    required int proposalId,
    required AdminDecision decision,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<WithdrawalCreationResult> resolveWithdrawal({
    required int requestId,
    required AdminDecision decision,
    String? reason,
  }) => throw UnimplementedError();
}

final _money0 = MoneyAmount.parse('0.00');
final _period = AdminPeriod(
  from: DateTime.utc(2026, 10, 1),
  to: DateTime.utc(2026, 10, 8),
  timezone: 'Asia/Ho_Chi_Minh',
);

final _summary = AdminDashboardSummary(
  period: _period,
  generatedAt: DateTime.utc(2026, 10, 8, 0, 0, 1),
  sandboxOnly: true,
  users: const AdminUserMetrics(
    total: 10,
    customers: 6,
    providers: 3,
    admins: 1,
    createdInPeriod: 2,
  ),
  providers: const AdminProviderMetrics(
    total: 3,
    pending: 1,
    approved: 2,
    rejected: 0,
    online: 1,
    freshLocation: 1,
  ),
  orders: AdminOrderMetrics(
    total: 0,
    byStatus: {for (final status in OrderStatus.values) status: 0},
    completionRate: 0,
  ),
  money: AdminMoneyMetrics(
    collectedInPeriod: _money0,
    heldCurrent: _money0,
    settledToProvidersInPeriod: _money0,
    refundPendingCurrent: _money0,
    refundedInPeriod: _money0,
    grossCompletedValueInPeriod: _money0,
    providerWalletBalanceCurrent: _money0,
    providerWalletLockedCurrent: _money0,
    providerWalletAvailableCurrent: _money0,
    pendingWithdrawalAmountCurrent: _money0,
    providerWithdrawnInPeriod: _money0,
  ),
);

final _timeseries = AdminTimeseries(
  period: _period,
  bucket: 'day',
  sandboxOnly: true,
  data: const [],
);

final _reconciliation = AdminReconciliationPage(
  period: _period,
  sandboxOnly: true,
  page: 1,
  limit: 50,
  total: 0,
  totalPages: 0,
  items: const [],
);

const _pendingProvider = PendingProviderApplication(
  id: 3,
  userId: 8,
  name: 'Tho mot',
  email: 'provider@example.test',
  phone: null,
  approvalStatus: ProviderApprovalStatus.pending,
  documentUrl: null,
);
