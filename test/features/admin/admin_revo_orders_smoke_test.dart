import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/app/app_dependencies.dart';
import 'package:moto_care/core/money/money_amount.dart';
import 'package:moto_care/features/admin/data/admin_repository.dart';
import 'package:moto_care/features/admin/domain/admin_analytics_models.dart';
import 'package:moto_care/features/admin/domain/admin_operation_models.dart';
import 'package:moto_care/features/admin/presentation/admin_shell.dart';
import 'package:moto_care/features/admin/revo/admin_orders_screen.dart';
import 'package:moto_care/features/auth/application/session_controller.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';
import 'package:moto_care/features/orders/domain/order_status.dart';
import 'package:moto_care/features/orders/domain/price_decision_result.dart';
import 'package:moto_care/features/payments/domain/demo_payment_result.dart';
import 'package:moto_care/features/wallet/domain/wallet_models.dart';

final _order = AdminRecentOrder(
  id: 2601,
  code: 'MC-2601',
  status: OrderStatus.completed,
  customerId: 12,
  providerId: 5,
  estimatedPrice: MoneyAmount.parse('180000.00'),
  finalPrice: MoneyAmount.parse('180000.00'),
  createdAt: DateTime.utc(2026, 10, 27, 13, 32),
);

final _detail = AdminOrderDetail(
  id: 2601,
  code: 'MC-2601',
  status: OrderStatus.completed,
  createdAt: DateTime.utc(2026, 10, 27, 13, 32),
  estimatedPrice: MoneyAmount.parse('180000.00'),
  extraCost: MoneyAmount.parse('0.00'),
  discountAmount: MoneyAmount.parse('0.00'),
  incidentType: 'Thủng lốp',
  finalPrice: MoneyAmount.parse('180000.00'),
  customer: const AdminOrderParty(
    name: 'Nguyễn Minh Anh',
    phone: '0900100201',
    address: '12 Nguyễn Huệ, Quận 1, TP. Hồ Chí Minh',
  ),
  provider: const AdminOrderProviderInfo(
    name: 'Trần Quốc Huy',
    phone: '0900000101',
  ),
);

void main() {
  testWidgets('revo admin orders list renders', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AdminShell(
          location: '/admin/orders',
          child: RevoAdminOrdersScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Quản lý đơn cứu hộ'), findsOneWidget);
    expect(find.text('MC-2601'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('revo admin order detail renders', (tester) async {
    await tester.pumpWidget(
      _wrap(const RevoAdminOrderDetailScreen(orderId: 2601)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Chi tiết đơn'), findsOneWidget);
    expect(find.textContaining('Nguyễn Minh Anh'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _wrap(Widget child) => ProviderScope(
  overrides: [
    runtimeApiIntegrationProvider.overrideWithValue(false),
    runtimeAllowedRolesProvider.overrideWithValue(const {
      AppRole.customer,
      AppRole.admin,
    }),
    sessionControllerProvider.overrideWith(_AdminSession.new),
    adminRepositoryProvider.overrideWithValue(_FakeAdminRepository()),
  ],
  child: MaterialApp(home: child),
);

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
  Future<List<AdminRecentOrder>> listRecentOrders() async => [_order];

  @override
  Future<AdminOrderDetail> getOrderDetail(int orderId) async => _detail;

  @override
  Future<List<PendingProviderApplication>> listPendingProviders() async =>
      const [];

  @override
  Future<AdminDashboardSummary> getDashboardSummary({
    DateTime? from,
    DateTime? to,
  }) async => throw UnimplementedError();

  @override
  Future<AdminTimeseries> getDashboardTimeseries({
    DateTime? from,
    DateTime? to,
  }) async => throw UnimplementedError();

  @override
  Future<AdminReconciliationPage> getReconciliation({
    DateTime? from,
    DateTime? to,
    PaymentStatus? status,
    int page = 1,
    int limit = 50,
  }) async => throw UnimplementedError();

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
