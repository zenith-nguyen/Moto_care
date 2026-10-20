import '../models/models.dart';

/// Read-only reporting: income is the Wallet credit ledger, never the seeded
/// dashboard counters or the available balance (which includes withdrawals).
class WeeklySummaryData {
  WeeklySummaryData({
    required Iterable<OrderHistoryItem> history,
    required Iterable<WalletTransaction> transactions,
    required DateTime anchor,
    required this.now,
    this.monthly = false,
  }) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    start = monthly
        ? DateTime(day.year, day.month)
        : DateTime(day.year, day.month, day.day - day.weekday + 1);
    end = monthly
        ? DateTime(day.year, day.month + 1)
        : DateTime(start.year, start.month, start.day + 7);
    bool inside(DateTime time) =>
        !time.isBefore(start) && time.isBefore(end) && !time.isAfter(now);
    credits = List.unmodifiable(
        transactions.where((tx) => tx.isCredit && inside(tx.time)).toList()
          ..sort((a, b) => b.time.compareTo(a.time)));
    final closed = history
        .where((o) => o.status != OrderStatus.active && inside(o.time))
        .toList();
    closedCount = closed.length;
    orders = List.unmodifiable(
        closed.where((o) => o.status == OrderStatus.completed).toList()
          ..sort((a, b) => b.time.compareTo(a.time)));
    final ratings = orders
        .map((o) => o.customerRating)
        .whereType<int>()
        .where((r) => r >= 1 && r <= 5)
        .toList();
    ratingCount = ratings.length;
    averageRating = ratings.isEmpty
        ? null
        : ratings.reduce((a, b) => a + b) / ratings.length;
    days = List.unmodifiable(List.generate(
        DateTime.utc(end.year, end.month, end.day)
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inDays,
        (i) => DateTime(start.year, start.month, start.day + i)));
    final today = DateTime(now.year, now.month, now.day);
    dailyIncome = List.unmodifiable(days.map((day) {
      // Future dates are unknown, rather than fabricated zero-income points.
      if (day.isAfter(today)) return null;
      final next = DateTime(day.year, day.month, day.day + 1);
      return credits
          .where((tx) => !tx.time.isBefore(day) && tx.time.isBefore(next))
          .fold<int>(0, (sum, tx) => sum + tx.amount);
    }));
  }

  final DateTime now;
  final bool monthly;
  late final DateTime start, end;
  late final List<DateTime> days;
  late final List<int?> dailyIncome;
  late final List<OrderHistoryItem> orders;
  late final List<WalletTransaction> credits;
  late final int closedCount, ratingCount;
  late final double? averageRating;

  int get income => credits.fold(0, (sum, tx) => sum + tx.amount);
  double? get completionRate =>
      closedCount == 0 ? null : orders.length / closedCount;
  int? incomeForOrder(String id) {
    final entries = credits.where((tx) => (tx.orderCode ?? tx.code) == id);
    return entries.isEmpty
        ? null
        : entries.fold<int>(0, (sum, tx) => sum + tx.amount);
  }

  /// Disclose ledger credits whose order detail is not in this period's source.
  int get unmatchedIncome => credits
      .where((tx) => !orders.any((o) => o.code == (tx.orderCode ?? tx.code)))
      .fold(0, (sum, tx) => sum + tx.amount);
}
