import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../domain/admin_operation_models.dart';
import 'admin_operations_state.dart';

final adminOperationsControllerProvider =
    AsyncNotifierProvider<AdminOperationsController, AdminOperationsState>(
      AdminOperationsController.new,
    );

class AdminOperationsController extends AsyncNotifier<AdminOperationsState> {
  @override
  Future<AdminOperationsState> build() async {
    final snapshot = await _load();
    return _toState(snapshot);
  }

  Future<void> refresh() async {
    await _run(AdminOperationsAction.refresh, null, () async {
      state = AsyncData(_toState(await _load()));
    });
  }

  Future<void> reviewProvider({
    required int providerId,
    required ProviderApprovalStatus status,
  }) async {
    await _run(AdminOperationsAction.reviewProvider, providerId, () async {
      final repository = ref.read(adminRepositoryProvider);
      await repository.reviewProvider(providerId: providerId, status: status);
      final providers = await repository.listPendingProviders();
      state = AsyncData(_requireState().copyWith(pendingProviders: providers));
    });
  }

  Future<void> refundFullOrder(int orderId) async {
    await _run(AdminOperationsAction.refundFullOrder, orderId, () async {
      final repository = ref.read(adminRepositoryProvider);
      await repository.refundFullOrder(orderId);
      final refundsFuture = repository.listPendingFullRefunds();
      final ordersFuture = repository.listRecentOrders();
      state = AsyncData(
        _requireState().copyWith(
          pendingFullRefunds: await refundsFuture,
          recentOrders: await ordersFuture,
        ),
      );
    });
  }

  Future<void> resolvePriceDispute({
    required int proposalId,
    required AdminDecision decision,
    required String reason,
  }) async {
    await _run(AdminOperationsAction.resolvePriceDispute, proposalId, () async {
      final repository = ref.read(adminRepositoryProvider);
      await repository.resolvePriceDispute(
        proposalId: proposalId,
        decision: decision,
        reason: reason,
      );
      final disputesFuture = repository.listPendingPriceDisputes();
      final adjustmentsFuture = repository.listPendingRefundAdjustments();
      final ordersFuture = repository.listRecentOrders();
      state = AsyncData(
        _requireState().copyWith(
          pendingPriceDisputes: await disputesFuture,
          pendingRefundAdjustments: await adjustmentsFuture,
          recentOrders: await ordersFuture,
        ),
      );
    });
  }

  Future<void> refundAdjustment(int orderId) async {
    await _run(AdminOperationsAction.refundAdjustment, orderId, () async {
      final repository = ref.read(adminRepositoryProvider);
      await repository.refundAdjustment(orderId);
      final adjustments = await repository.listPendingRefundAdjustments();
      state = AsyncData(
        _requireState().copyWith(pendingRefundAdjustments: adjustments),
      );
    });
  }

  Future<void> resolveWithdrawal({
    required int requestId,
    required AdminDecision decision,
    String? reason,
  }) async {
    await _run(AdminOperationsAction.resolveWithdrawal, requestId, () async {
      final repository = ref.read(adminRepositoryProvider);
      await repository.resolveWithdrawal(
        requestId: requestId,
        decision: decision,
        reason: reason,
      );
      final withdrawals = await repository.listPendingWithdrawals();
      state = AsyncData(
        _requireState().copyWith(pendingWithdrawals: withdrawals),
      );
    });
  }

  Future<void> _run(
    AdminOperationsAction action,
    int? targetId,
    Future<void> Function() operation,
  ) async {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(
      current.copyWith(
        action: action,
        actionTargetId: targetId,
        lastFailure: null,
      ),
    );
    try {
      await operation();
      state = AsyncData(
        _requireState().copyWith(action: null, actionTargetId: null),
      );
    } catch (error) {
      state = AsyncData(
        _requireState().copyWith(
          action: null,
          actionTargetId: null,
          lastFailure: error,
        ),
      );
    }
  }

  Future<AdminOperationsSnapshot> _load() async {
    final repository = ref.read(adminRepositoryProvider);
    final ordersFuture = repository.listRecentOrders();
    final providersFuture = repository.listPendingProviders();
    final refundsFuture = repository.listPendingFullRefunds();
    final disputesFuture = repository.listPendingPriceDisputes();
    final adjustmentsFuture = repository.listPendingRefundAdjustments();
    final withdrawalsFuture = repository.listPendingWithdrawals();
    return AdminOperationsSnapshot(
      recentOrders: await ordersFuture,
      pendingProviders: await providersFuture,
      pendingFullRefunds: await refundsFuture,
      pendingPriceDisputes: await disputesFuture,
      pendingRefundAdjustments: await adjustmentsFuture,
      pendingWithdrawals: await withdrawalsFuture,
    );
  }

  AdminOperationsState _toState(AdminOperationsSnapshot snapshot) {
    return AdminOperationsState(
      recentOrders: snapshot.recentOrders,
      pendingProviders: snapshot.pendingProviders,
      pendingFullRefunds: snapshot.pendingFullRefunds,
      pendingPriceDisputes: snapshot.pendingPriceDisputes,
      pendingRefundAdjustments: snapshot.pendingRefundAdjustments,
      pendingWithdrawals: snapshot.pendingWithdrawals,
    );
  }

  AdminOperationsState _requireState() {
    return state.value ??
        (throw StateError('Admin operations are not loaded.'));
  }
}

class AdminOperationsSnapshot {
  const AdminOperationsSnapshot({
    required this.recentOrders,
    required this.pendingProviders,
    required this.pendingFullRefunds,
    required this.pendingPriceDisputes,
    required this.pendingRefundAdjustments,
    required this.pendingWithdrawals,
  });

  final List<AdminRecentOrder> recentOrders;
  final List<PendingProviderApplication> pendingProviders;
  final List<PendingFullRefund> pendingFullRefunds;
  final List<AdminPriceDispute> pendingPriceDisputes;
  final List<PendingRefundAdjustment> pendingRefundAdjustments;
  final List<AdminWithdrawal> pendingWithdrawals;
}
