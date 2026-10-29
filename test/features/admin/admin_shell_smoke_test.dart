import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/core/money/money_amount.dart';
import 'package:moto_care/features/admin/data/admin_repository.dart';
import 'package:moto_care/features/admin/domain/admin_analytics_models.dart';
import 'package:moto_care/features/admin/domain/admin_operation_models.dart';
import 'package:moto_care/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:moto_care/features/admin/presentation/admin_shell.dart';
import 'package:moto_care/features/auth/application/session_controller.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';
import 'package:moto_care/features/orders/domain/order_status.dart';
import 'package:moto_care/features/orders/domain/price_decision_result.dart';
import 'package:moto_care/features/payments/domain/demo_payment_result.dart';
import 'package:moto_care/features/wallet/domain/wallet_models.dart';

/// Guards the admin shell render path (regression for the blank-screen report):
/// the 6-tab shell wrapping the dashboard must build without throwing when it
/// is handed a signed-in admin session and real-shaped (demo) data.
void main() {
  testWidgets('admin shell + dashboard render without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runtimeApiIntegrationProvider.overrideWithValue(false),
          runtimeAllowedRolesProvider.overrideWithValue(const {
            AppRole.customer,
            AppRole.admin,
          }),
          sessionControllerProvider.overrideWith(_AdminSession.new),
          adminRepositoryProvider.overrideWithValue(_FakeAdminRepository()),
        ],
        child: const MaterialApp(
          home: AdminShell(location: '/admin', child: AdminDashboardScreen()),
        ),
      ),
    );

    // Let the async dashboard controller resolve the demo data.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The floating 6-tab nav rendered (shell is healthy)...
    expect(find.byTooltip('Tổng quan'), findsOneWidget);
    expect(find.byTooltip('Tài khoản'), findsOneWidget);
    // ...and the dashboard built its content instead of blanking out.
    expect(find.text('Tài chính'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _AdminSession extends SessionController {
  @override
  SessionState build() => const SessionSignedIn(
    AuthSession(
      accessToken: 'test-token',
      user: AppUser(
        id: 1,
        name: 'Quản trị REVO',
        email: 'admin@revo.vn',
        phone: '0900000000',
        role: AppRole.admin,
        status: AppUserStatus.active,
      ),
    ),
  );
}

class _FakeAdminRepository implements AdminRepository {
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
  }) async => _reconciliation;

  @override
  Future<List<AdminRecentOrder>> listRecentOrders() async => const [];

  @override
  Future<AdminOrderDetail> getOrderDetail(int orderId) async =>
      throw UnimplementedError();

  @override
  Future<List<PendingProviderApplication>> listPendingProviders() async =>
      const [];

  @override
  Future<ProviderReviewResult> reviewProvider({
    required int providerId,
    required ProviderApprovalStatus status,
  }) async => throw UnimplementedError();

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

  @override
  Future<List<AdminWithdrawalPayout>> listPendingWithdrawalPayouts() async =>
      const [];

  @override
  Future<AdminWithdrawalPayout> reconcileWithdrawalPayout({
    required int payoutId,
    required PayoutReconciliationDecision decision,
    String? externalTransactionId,
    String? referenceCode,
    String? observedAmount,
    String? reason,
  }) async => throw UnimplementedError();
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
