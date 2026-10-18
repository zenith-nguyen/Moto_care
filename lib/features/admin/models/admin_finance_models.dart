import 'admin_models.dart';

/// Finance values retain the repository's cash-flow and reconciliation rules.
class AdminFinanceSnapshot {
  AdminFinanceSnapshot({
    required this.summary,
    required List<AdminReconciliation> invoices,
  }) : invoices = List.unmodifiable(invoices);

  final AdminDashboardSummary summary;
  final List<AdminReconciliation> invoices;

  int _metric(String label) => summary.metrics
      .where((metric) => metric.label == label)
      .fold(0, (total, metric) => total + metric.value);

  int get collected => _metric('Đã thu');
  int get held => _metric('Đang giữ / chưa quyết toán');
  int get credited => _metric('Đã cộng ví thợ');
  bool get isEmpty =>
      invoices.isEmpty && collected == 0 && held == 0 && credited == 0;

  DateTime? get latestTransactionAt {
    DateTime? latest;
    for (final invoice in invoices) {
      for (final payment in invoice.order.payments) {
        if (latest == null || payment.at.isAfter(latest)) latest = payment.at;
      }
    }
    return latest;
  }
}
