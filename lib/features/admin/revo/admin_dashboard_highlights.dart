/// Dashboard view-models for the REVO admin look, populated from our real
/// backend data (not mock). The view never invents chart samples or totals.
class AdminDateRange {
  const AdminDateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is AdminDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  /// The equal-length period immediately before this one, for comparisons.
  AdminDateRange get previous {
    final days = DateTime(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime(start.year, start.month, start.day)).inDays;
    return AdminDateRange(
      DateTime(start.year, start.month, start.day - days),
      start,
    );
  }
}

/// A single day in the dashboard series (orders + money in whole VND).
class RevoTimeseriesPoint {
  const RevoTimeseriesPoint({
    required this.day,
    required this.orders,
    required this.collected,
    required this.refunded,
    required this.credited,
  });

  final DateTime day;
  final int orders;
  final int collected;
  final int refunded;
  final int credited;
}

/// Derived dashboard values built from the real summary + timeseries.
class AdminDashboardHighlights {
  const AdminDashboardHighlights({
    required this.metrics,
    required this.points,
    required this.previousPoints,
  });

  /// Named current totals (Tổng khách, Thợ online, Tổng thợ, ...), from the
  /// real dashboard summary + pending-operations counts.
  final Map<String, int> metrics;
  final List<RevoTimeseriesPoint> points;
  final List<RevoTimeseriesPoint> previousPoints;

  int metric(String label) => metrics[label] ?? 0;

  int get orders => points.fold(0, (sum, point) => sum + point.orders);
  int get previousOrders =>
      previousPoints.fold(0, (sum, point) => sum + point.orders);
  int get collected => points.fold(0, (sum, point) => sum + point.collected);
  double get dailyOrdersAverage => points.isEmpty ? 0 : orders / points.length;
  double get dailyAverage => points.isEmpty ? 0 : collected / points.length;

  bool get isEmpty =>
      orders == 0 && collected == 0 && metrics.values.every((v) => v == 0);
}
