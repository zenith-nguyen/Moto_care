import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/money/money_amount.dart';
import '../../orders/domain/order_status.dart';
import '../application/admin_operations_controller.dart';
import '../domain/admin_analytics_models.dart';
import '../domain/admin_operation_models.dart';
import 'admin_dashboard_highlights.dart';

int _moneyToInt(MoneyAmount amount) =>
    (double.tryParse(amount.value) ?? 0).round();

RevoTimeseriesPoint _point(AdminTimeseriesPoint p) => RevoTimeseriesPoint(
  day: DateTime.parse(p.day),
  orders: p.ordersCreated,
  collected: _moneyToInt(p.collected),
  refunded: _moneyToInt(p.refunded),
  credited: _moneyToInt(p.settledToProviders),
);

/// Builds the dashboard highlights from the REAL backend (summary + timeseries
/// for the chosen range and the equal-length previous range) plus the real
/// pending-operations counts. No mock, no invented numbers.
final adminDashboardHighlightsProvider = FutureProvider.autoDispose
    .family<AdminDashboardHighlights, AdminDateRange>((ref, range) async {
      final repo = ref.watch(adminRepositoryProvider);
      final previous = range.previous;

      final AdminDashboardSummary summary = await repo.getDashboardSummary(
        from: range.start,
        to: range.end,
      );
      final AdminTimeseries timeseries = await repo.getDashboardTimeseries(
        from: range.start,
        to: range.end,
      );
      final AdminTimeseries previousSeries = await repo.getDashboardTimeseries(
        from: previous.start,
        to: previous.end,
      );

      // Pending actions are real but must never break the dashboard: fall back
      // to zero if the operations queue is still loading or unreachable.
      var pendingTotal = 0;
      var pendingOrders = 0;
      try {
        final ops = await ref.watch(adminOperationsControllerProvider.future);
        pendingOrders =
            ops.pendingFullRefunds.length + ops.pendingRefundAdjustments.length;
        pendingTotal =
            pendingOrders +
            ops.pendingPriceDisputes.length +
            ops.pendingWithdrawals.length;
      } catch (_) {
        pendingTotal = 0;
        pendingOrders = 0;
      }

      return AdminDashboardHighlights(
        metrics: {
          'Tổng khách': summary.users.customers,
          'Thợ online': summary.providers.online,
          'Tổng thợ': summary.providers.total,
          'Thợ chờ duyệt': pendingTotal,
          'Đơn đang làm': pendingOrders,
        },
        points: timeseries.data.map(_point).toList(growable: false),
        previousPoints: previousSeries.data.map(_point).toList(growable: false),
      );
    });

/// Active rescue cases (not terminal, past prepayment) for the SOS queue.
final adminUrgentOrdersProvider =
    FutureProvider.autoDispose<List<AdminRecentOrder>>((ref) async {
      final repo = ref.watch(adminRepositoryProvider);
      final orders = await repo.listRecentOrders();
      return orders
          .where(
            (o) =>
                !o.status.isTerminal &&
                o.status != OrderStatus.awaitingPrepayment,
          )
          .toList(growable: false);
    });
