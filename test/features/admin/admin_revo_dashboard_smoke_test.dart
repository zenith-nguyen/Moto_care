import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/core/money/money_amount.dart';
import 'package:moto_care/features/admin/data/admin_repository.dart';
import 'package:moto_care/features/admin/domain/admin_analytics_models.dart';
import 'package:moto_care/features/admin/domain/admin_operation_models.dart';
import 'package:moto_care/features/admin/presentation/admin_shell.dart';
import 'package:moto_care/features/admin/revo/admin_dashboard_screen.dart';
import 'package:moto_care/features/auth/application/session_controller.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';
import 'package:moto_care/features/home/providers/home_weather_provider.dart';
import 'package:moto_care/features/orders/domain/order_status.dart';
import 'package:moto_care/features/orders/domain/price_decision_result.dart';
import 'package:moto_care/features/payments/domain/demo_payment_result.dart';
import 'package:moto_care/features/wallet/domain/wallet_models.dart';

/// Render guard for the REVO dashboard (Tổng quan): it must build inside the
/// shell with real-shaped backend data without throwing, and never fabricate a
/// weather surcharge (the card uses the real weather provider only).
void main() {
  testWidgets('revo admin dashboard renders without crashing', (tester) async {
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
          // Keep weather deterministic and offline in tests.
          homeWeatherProvider.overrideWith((ref) => throw Exception('offline')),
        ],
        child: const MaterialApp(
          home: AdminShell(
            location: '/admin',
            child: AdminRevoDashboardScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.byTooltip('Tài khoản'), findsOneWidget);
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

final _period = AdminPeriod(
  from: DateTime.utc(2026, 10, 21),
  to: DateTime.utc(2026, 10, 28),
  timezone: 'Asia/Ho_Chi_Minh',
);

final _summary = AdminDashboardSummary(
  period: _period,
  generatedAt: DateTime.utc(2026, 10, 28),
  sandboxOnly: true,
  users: const AdminUserMetrics(
    total: 1248,
    customers: 1248,
    providers: 86,
    admins: 1,
    createdInPeriod: 20,
  ),
  providers: const AdminProviderMetrics(
    total: 86,
    pending: 3,
    approved: 80,
    rejected: 3,
    online: 24,
    freshLocation: 20,
  ),
  orders: AdminOrderMetrics(
    total: 8,
    byStatus: {for (final status in OrderStatus.values) status: 1},
    completionRate: 62.5,
  ),
  money: AdminMoneyMetrics(
    collectedInPeriod: MoneyAmount.parse('1350000.00'),
    heldCurrent: MoneyAmount.parse('0.00'),
    settledToProvidersInPeriod: MoneyAmount.parse('900000.00'),
    refundPendingCurrent: MoneyAmount.parse('0.00'),
    refundedInPeriod: MoneyAmount.parse('160000.00'),
    grossCompletedValueInPeriod: MoneyAmount.parse('1350000.00'),
    providerWalletBalanceCurrent: MoneyAmount.parse('0.00'),
    providerWalletLockedCurrent: MoneyAmount.parse('0.00'),
    providerWalletAvailableCurrent: MoneyAmount.parse('0.00'),
    pendingWithdrawalAmountCurrent: MoneyAmount.parse('0.00'),
    providerWithdrawnInPeriod: MoneyAmount.parse('0.00'),
  ),
);

AdminTimeseriesPoint _pt(int day, int orders, String collected) =>
    AdminTimeseriesPoint(
      day: '2026-10-${day.toString().padLeft(2, '0')}',
      ordersCreated: orders,
      ordersCompleted: orders,
      collected: MoneyAmount.parse(collected),
      settledToProviders: MoneyAmount.parse('0.00'),
      refunded: MoneyAmount.parse('0.00'),
      providerWithdrawn: MoneyAmount.parse('0.00'),
    );

final _timeseries = AdminTimeseries(
  period: _period,
  bucket: 'day',
  sandboxOnly: true,
  data: [_pt(26, 6, '300000.00'), _pt(27, 2, '420000.00')],
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
