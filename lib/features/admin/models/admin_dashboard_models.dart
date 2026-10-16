import 'admin_models.dart';

/// Derived dashboard values; the view never invents chart samples or totals.
class AdminDashboardHighlights {
  const AdminDashboardHighlights({
    required this.summary,
    required this.points,
    required this.previousPoints,
  });

  final AdminDashboardSummary summary;
  final List<AdminTimeseriesPoint> points;
  final List<AdminTimeseriesPoint> previousPoints;

  int metric(String label) => summary.metrics
      .where((metric) => metric.label == label)
      .fold(0, (sum, metric) => sum + metric.value);

  int get orders => points.fold(0, (sum, point) => sum + point.orders);
  int get previousOrders =>
      previousPoints.fold(0, (sum, point) => sum + point.orders);
  int get collected => points.fold(0, (sum, point) => sum + point.collected);
  double get dailyOrdersAverage => points.isEmpty ? 0 : orders / points.length;
  double get dailyAverage => points.isEmpty ? 0 : collected / points.length;
  bool get isEmpty => summary.metrics.every((metric) => metric.value == 0);

  static AdminDateRange previousRange(AdminDateRange range) {
    final days = DateTime.utc(range.end.year, range.end.month, range.end.day)
        .difference(
          DateTime.utc(range.start.year, range.start.month, range.start.day),
        )
        .inDays;
    return AdminDateRange(
      DateTime(range.start.year, range.start.month, range.start.day - days),
      range.start,
    );
  }
}

class AdminDashboardMoneyQueue {
  const AdminDashboardMoneyQueue(this.refunds, this.withdrawals);
  final List<AdminRefund> refunds;
  final List<AdminWithdrawal> withdrawals;
  bool get isEmpty => refunds.isEmpty && withdrawals.isEmpty;
  int get total => refunds.length + withdrawals.length;
}
