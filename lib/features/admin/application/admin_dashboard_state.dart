import '../../orders/domain/order_status.dart';
import '../domain/admin_analytics_models.dart';

enum AdminDashboardAction { refresh, changePeriod, changeReconciliation }

class AdminDashboardState {
  const AdminDashboardState({
    required this.summary,
    required this.timeseries,
    required this.reconciliation,
    this.paymentFilter,
    this.action,
    this.lastFailure,
  });

  final AdminDashboardSummary summary;
  final AdminTimeseries timeseries;
  final AdminReconciliationPage reconciliation;
  final PaymentStatus? paymentFilter;
  final AdminDashboardAction? action;
  final Object? lastFailure;

  bool get isBusy => action != null;

  AdminDashboardState copyWith({
    AdminDashboardSummary? summary,
    AdminTimeseries? timeseries,
    AdminReconciliationPage? reconciliation,
    Object? paymentFilter = _unchanged,
    Object? action = _unchanged,
    Object? lastFailure = _unchanged,
  }) {
    return AdminDashboardState(
      summary: summary ?? this.summary,
      timeseries: timeseries ?? this.timeseries,
      reconciliation: reconciliation ?? this.reconciliation,
      paymentFilter: identical(paymentFilter, _unchanged)
          ? this.paymentFilter
          : paymentFilter as PaymentStatus?,
      action: identical(action, _unchanged)
          ? this.action
          : action as AdminDashboardAction?,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
