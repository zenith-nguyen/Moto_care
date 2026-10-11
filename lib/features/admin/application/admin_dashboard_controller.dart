import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../orders/domain/order_status.dart';
import '../domain/admin_analytics_models.dart';
import 'admin_dashboard_state.dart';

final adminDashboardControllerProvider =
    AsyncNotifierProvider<AdminDashboardController, AdminDashboardState>(
      AdminDashboardController.new,
    );

class AdminDashboardController extends AsyncNotifier<AdminDashboardState> {
  @override
  Future<AdminDashboardState> build() async {
    final snapshot = await _load();
    return AdminDashboardState(
      summary: snapshot.summary,
      timeseries: snapshot.timeseries,
      reconciliation: snapshot.reconciliation,
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    await _run(AdminDashboardAction.refresh, () async {
      final period = current.summary.period;
      final snapshot = await _load(
        from: period.from,
        to: period.to,
        status: current.paymentFilter,
        page: current.reconciliation.page,
      );
      state = AsyncData(
        _requireState().copyWith(
          summary: snapshot.summary,
          timeseries: snapshot.timeseries,
          reconciliation: snapshot.reconciliation,
        ),
      );
    });
  }

  Future<void> changePeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    await _run(AdminDashboardAction.changePeriod, () async {
      final snapshot = await _load(
        from: from,
        to: to,
        status: _requireState().paymentFilter,
      );
      state = AsyncData(
        _requireState().copyWith(
          summary: snapshot.summary,
          timeseries: snapshot.timeseries,
          reconciliation: snapshot.reconciliation,
        ),
      );
    });
  }

  Future<void> changeReconciliation({
    PaymentStatus? paymentStatus,
    int page = 1,
  }) async {
    await _run(AdminDashboardAction.changeReconciliation, () async {
      final current = _requireState();
      final period = current.summary.period;
      final reconciliation = await ref
          .read(adminRepositoryProvider)
          .getReconciliation(
            from: period.from,
            to: period.to,
            status: paymentStatus,
            page: page,
          );
      state = AsyncData(
        _requireState().copyWith(
          reconciliation: reconciliation,
          paymentFilter: paymentStatus,
        ),
      );
    });
  }

  Future<void> _run(
    AdminDashboardAction action,
    Future<void> Function() operation,
  ) async {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(current.copyWith(action: action, lastFailure: null));
    try {
      await operation();
      state = AsyncData(_requireState().copyWith(action: null));
    } catch (error) {
      state = AsyncData(
        _requireState().copyWith(action: null, lastFailure: error),
      );
    }
  }

  Future<AdminDashboardSnapshot> _load({
    DateTime? from,
    DateTime? to,
    PaymentStatus? status,
    int page = 1,
  }) async {
    final repository = ref.read(adminRepositoryProvider);
    final summary = await repository.getDashboardSummary(from: from, to: to);
    final effectiveFrom = from ?? summary.period.from;
    final effectiveTo = to ?? summary.period.to;
    final timeseriesFuture = repository.getDashboardTimeseries(
      from: effectiveFrom,
      to: effectiveTo,
    );
    final reconciliationFuture = repository.getReconciliation(
      from: effectiveFrom,
      to: effectiveTo,
      status: status,
      page: page,
    );
    return AdminDashboardSnapshot(
      summary: summary,
      timeseries: await timeseriesFuture,
      reconciliation: await reconciliationFuture,
    );
  }

  AdminDashboardState _requireState() {
    return state.value ?? (throw StateError('Admin dashboard is not loaded.'));
  }
}

class AdminDashboardSnapshot {
  const AdminDashboardSnapshot({
    required this.summary,
    required this.timeseries,
    required this.reconciliation,
  });

  final AdminDashboardSummary summary;
  final AdminTimeseries timeseries;
  final AdminReconciliationPage reconciliation;
}
