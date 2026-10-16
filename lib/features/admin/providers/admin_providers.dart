import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_models.dart';
import '../models/admin_dashboard_models.dart';
import '../models/admin_account_models.dart';
import '../services/admin_repository.dart';
import '../services/mock_admin_repository.dart';

final adminSessionProvider =
    NotifierProvider<AdminSessionController, AdminSession?>(
      AdminSessionController.new,
    );

/// Auth integration calls setSession with the verified backend identity.
/// Missing/other roles fail closed; routes never grant ADMIN from URL inputs.
class AdminSessionController extends Notifier<AdminSession?> {
  AdminSessionController({this.initialSession});
  final AdminSession? initialSession;
  @override
  AdminSession? build() => initialSession;
  void setSession(AdminSession? session) => state = session;
  void signOut() => state = null;
}

void requireAdmin(Ref ref) {
  if (ref.watch(adminSessionProvider)?.isAdmin != true) {
    throw const AdminException(
      'Bạn không có quyền truy cập khu vực này',
      forbidden: true,
    );
  }
}

// Admin errors remain visible until an explicit Retry; forbidden requests
// must never enter Riverpod's default automatic retry loop.
Duration? adminManualRetry(int retryCount, Object error) => null;

final adminClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final adminAuditTrailProvider =
    NotifierProvider<AdminAuditTrailController, List<AdminAuditEntry>>(
      AdminAuditTrailController.new,
    );

class AdminAuditTrailController extends Notifier<List<AdminAuditEntry>> {
  @override
  List<AdminAuditEntry> build() {
    ref.watch(adminSessionProvider);
    return const [];
  }

  void record(String action, String target) {
    final actor = ref.read(adminSessionProvider);
    if (actor?.isAdmin != true) return;
    state = List.unmodifiable([
      AdminAuditEntry(
        actorId: actor!.id,
        actorName: actor.name,
        action: action,
        target: target,
        at: ref.read(adminClockProvider)(),
      ),
      ...state,
    ]);
  }
}

/// Replace with credential revocation/secure-storage cleanup during auth wiring.
final adminSignOutServiceProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);
final adminSignOutProvider =
    NotifierProvider<AdminSignOutController, AsyncValue<void>>(
      AdminSignOutController.new,
    );

class AdminSignOutController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    ref.watch(adminSessionProvider);
    return const AsyncData(null);
  }

  Future<bool> signOut() async {
    if (state.isLoading) return false;
    final session = ref.read(adminSessionProvider);
    if (session?.isAdmin != true) return false;
    state = const AsyncLoading();
    try {
      await ref.read(adminSignOutServiceProvider)();
      if (!ref.mounted || ref.read(adminSessionProvider) != session) {
        return false;
      }
      ref.read(adminSessionProvider.notifier).signOut();
      return true;
    } catch (error, stack) {
      if (ref.mounted && ref.read(adminSessionProvider) == session) {
        state = AsyncError(error, stack);
      }
      return false;
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  // A new session gets a new in-memory repository, including wallets/drafts.
  requireAdmin(ref);
  return MockAdminRepository(clock: ref.watch(adminClockProvider));
});

final adminOrdersProvider = FutureProvider<List<AdminOrder>>((ref) {
  requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).orders();
}, retry: adminManualRetry);
final adminOrderDetailProvider = FutureProvider.family<AdminOrder?, String>((
  ref,
  id,
) async {
  requireAdmin(ref);
  final orders = await ref.watch(adminOrdersProvider.future);
  for (final order in orders) {
    if (order.id == id) return order;
  }
  return null;
}, retry: adminManualRetry);
final adminProvidersProvider = FutureProvider<List<AdminProviderApplication>>((
  ref,
) {
  requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).pendingProviders();
}, retry: adminManualRetry);
final adminReconciliationProvider = FutureProvider<List<AdminReconciliation>>((
  ref,
) {
  requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).reconciliation();
}, retry: adminManualRetry);
final adminRefundsProvider = FutureProvider<List<AdminRefund>>((ref) async {
  requireAdmin(ref);
  final repository = ref.watch(adminRepositoryProvider);
  final lists = await Future.wait([
    repository.pendingRefunds(),
    repository.pendingAdjustmentRefunds(),
  ]);
  final unique = <String, AdminRefund>{};
  for (final item in lists.expand((items) => items)) {
    unique[item.id] = item;
  }
  return List.unmodifiable(unique.values);
}, retry: adminManualRetry);
final adminDisputesProvider = FutureProvider<List<AdminPriceDispute>>((ref) {
  requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).pendingDisputes();
}, retry: adminManualRetry);
final adminWithdrawalsProvider = FutureProvider<List<AdminWithdrawal>>((ref) {
  requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).pendingWithdrawals();
}, retry: adminManualRetry);
final adminWalletProvider = FutureProvider.family<AdminWallet, String>((
  ref,
  id,
) {
  requireAdmin(ref);
  return ref.watch(adminRepositoryProvider).wallet(id);
}, retry: adminManualRetry);
final adminWithdrawalDetailsProvider =
    FutureProvider<List<AdminWithdrawalSnapshot>>((ref) async {
      requireAdmin(ref);
      final requests = await ref.watch(adminWithdrawalsProvider.future);
      return Future.wait(
        requests.map(
          (request) async => AdminWithdrawalSnapshot(
            request,
            await ref.watch(adminWalletProvider(request.providerId).future),
          ),
        ),
      );
    }, retry: adminManualRetry);
final adminSummaryProvider =
    FutureProvider.family<AdminDashboardSummary, AdminDateRange>((ref, range) {
      requireAdmin(ref);
      return ref.watch(adminRepositoryProvider).dashboardSummary(range);
    }, retry: adminManualRetry);
final adminTimeseriesProvider =
    FutureProvider.family<List<AdminTimeseriesPoint>, AdminDateRange>((
      ref,
      range,
    ) {
      requireAdmin(ref);
      return ref.watch(adminRepositoryProvider).dashboardTimeseries(range);
    }, retry: adminManualRetry);
final adminPendingCountsProvider = FutureProvider<AdminPendingCounts>((
  ref,
) async {
  requireAdmin(ref);
  // Start independently; a failed count is never presented as zero pending.
  final results = await Future.wait<Object>([
    ref.watch(adminRefundsProvider.future),
    ref.watch(adminDisputesProvider.future),
    ref.watch(adminWithdrawalsProvider.future),
  ]);
  return AdminPendingCounts(
    (results[0] as List).length,
    (results[1] as List).length,
    (results[2] as List).length,
  );
}, retry: adminManualRetry);

final adminDashboardHighlightsProvider =
    FutureProvider.family<AdminDashboardHighlights, AdminDateRange>((
      ref,
      range,
    ) async {
      requireAdmin(ref);
      final values = await Future.wait<Object>([
        ref.watch(adminSummaryProvider(range).future),
        ref.watch(adminTimeseriesProvider(range).future),
        ref.watch(
          adminTimeseriesProvider(AdminDashboardHighlights.previousRange(range))
              .future,
        ),
      ]);
      return AdminDashboardHighlights(
        summary: values[0] as AdminDashboardSummary,
        points: values[1] as List<AdminTimeseriesPoint>,
        previousPoints: values[2] as List<AdminTimeseriesPoint>,
      );
    }, retry: adminManualRetry);

/// Operational queues always reflect the current backlog, independently of
/// the historical period selected for charts.
final adminDashboardUrgentOrdersProvider =
    Provider<AsyncValue<List<AdminOrder>>>((ref) {
      return ref.watch(adminOrdersProvider).whenData((orders) {
        final pending = orders
            .where(
              (order) =>
                  order.status == AdminOrderStatus.searching ||
                  order.status == AdminOrderStatus.assigned,
            )
            .toList();
        pending.sort((a, b) {
          final priority = a.status.index.compareTo(b.status.index);
          return priority == 0 ? a.createdAt.compareTo(b.createdAt) : priority;
        });
        return List.unmodifiable(pending);
      });
    });

final adminDashboardMoneyQueueProvider =
    FutureProvider<AdminDashboardMoneyQueue>((ref) async {
      requireAdmin(ref);
      final values = await Future.wait<Object>([
        ref.watch(adminRefundsProvider.future),
        ref.watch(adminWithdrawalsProvider.future),
      ]);
      return AdminDashboardMoneyQueue(
        values[0] as List<AdminRefund>,
        values[1] as List<AdminWithdrawal>,
      );
    }, retry: adminManualRetry);

final adminOrderFilterProvider =
    NotifierProvider<AdminOrderFilterController, AdminOrderFilter>(
      AdminOrderFilterController.new,
    );

class AdminOrderFilterController extends Notifier<AdminOrderFilter> {
  @override
  AdminOrderFilter build() {
    ref.watch(adminSessionProvider);
    return const AdminOrderFilter();
  }

  void update(AdminOrderFilter filter) => state = filter;
}

final adminFilteredOrdersProvider = Provider<AsyncValue<List<AdminOrder>>>((
  ref,
) {
  final filter = ref.watch(adminOrderFilterProvider);
  return ref.watch(adminOrdersProvider).whenData((orders) {
    final query = filter.search.trim().toLowerCase();
    return orders
        .where(
          (o) =>
              (filter.status == null || o.status == filter.status) &&
              (filter.payment == null || o.payment == filter.payment) &&
              (filter.range == null || filter.range!.contains(o.createdAt)) &&
              (query.isEmpty ||
                  '${o.id} ${o.customer} ${o.provider ?? ''}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList();
  });
});

enum AdminActionKind { provider, dispute, withdrawal }

final adminActionProvider =
    NotifierProvider<AdminActionController, AsyncValue<void>>(
      AdminActionController.new,
    );

class AdminActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    ref.watch(adminSessionProvider);
    return const AsyncData(null);
  }

  Future<bool> resolve(
    AdminActionKind kind,
    String id, {
    required bool approve,
    required String note,
  }) async {
    if (state.isLoading) return false;
    final session = ref.read(adminSessionProvider);
    if (session?.isAdmin != true) {
      state = const AsyncError(
        AdminException(
          'Bạn không có quyền truy cập khu vực này',
          forbidden: true,
        ),
        StackTrace.empty,
      );
      return false;
    }
    final repository = ref.read(adminRepositoryProvider);
    state = const AsyncLoading();
    try {
      switch (kind) {
        case AdminActionKind.provider:
          await repository.resolveProvider(id, approve: approve, note: note);
        case AdminActionKind.dispute:
          await repository.resolveDispute(id, approve: approve, note: note);
        case AdminActionKind.withdrawal:
          await repository.resolveWithdrawal(id, approve: approve, note: note);
      }
      if (!ref.mounted || ref.read(adminSessionProvider) != session) {
        return false;
      }
      state = const AsyncData(null);
      ref
          .read(adminAuditTrailProvider.notifier)
          .record(
            '${approve ? 'Duyệt' : 'Từ chối'} ${switch (kind) {
              AdminActionKind.provider => 'hồ sơ thợ',
              AdminActionKind.dispute => 'đề xuất giá',
              AdminActionKind.withdrawal => 'rút tiền',
            }}',
            id,
          );
      ref.invalidate(adminProvidersProvider);
      ref.invalidate(adminOrdersProvider);
      ref.invalidate(adminDisputesProvider);
      ref.invalidate(adminWithdrawalsProvider);
      ref.invalidate(adminWalletProvider);
      ref.invalidate(adminReconciliationProvider);
      ref.invalidate(adminSummaryProvider);
      ref.invalidate(adminTimeseriesProvider);
      return true;
    } catch (error, stack) {
      if (ref.mounted && ref.read(adminSessionProvider) == session) {
        state = AsyncError(error, stack);
      }
      return false;
    }
  }
}
