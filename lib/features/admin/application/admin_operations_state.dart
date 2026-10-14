import '../domain/admin_operation_models.dart';

enum AdminOperationsAction {
  refresh,
  reviewProvider,
  refundFullOrder,
  resolvePriceDispute,
  refundAdjustment,
  resolveWithdrawal,
}

class AdminOperationsState {
  const AdminOperationsState({
    required this.recentOrders,
    required this.pendingProviders,
    required this.pendingFullRefunds,
    required this.pendingPriceDisputes,
    required this.pendingRefundAdjustments,
    required this.pendingWithdrawals,
    this.action,
    this.actionTargetId,
    this.lastFailure,
  });

  final List<AdminRecentOrder> recentOrders;
  final List<PendingProviderApplication> pendingProviders;
  final List<PendingFullRefund> pendingFullRefunds;
  final List<AdminPriceDispute> pendingPriceDisputes;
  final List<PendingRefundAdjustment> pendingRefundAdjustments;
  final List<AdminWithdrawal> pendingWithdrawals;
  final AdminOperationsAction? action;
  final int? actionTargetId;
  final Object? lastFailure;

  bool get isBusy => action != null;

  AdminOperationsState copyWith({
    List<AdminRecentOrder>? recentOrders,
    List<PendingProviderApplication>? pendingProviders,
    List<PendingFullRefund>? pendingFullRefunds,
    List<AdminPriceDispute>? pendingPriceDisputes,
    List<PendingRefundAdjustment>? pendingRefundAdjustments,
    List<AdminWithdrawal>? pendingWithdrawals,
    Object? action = _unchanged,
    Object? actionTargetId = _unchanged,
    Object? lastFailure = _unchanged,
  }) {
    return AdminOperationsState(
      recentOrders: recentOrders ?? this.recentOrders,
      pendingProviders: pendingProviders ?? this.pendingProviders,
      pendingFullRefunds: pendingFullRefunds ?? this.pendingFullRefunds,
      pendingPriceDisputes: pendingPriceDisputes ?? this.pendingPriceDisputes,
      pendingRefundAdjustments:
          pendingRefundAdjustments ?? this.pendingRefundAdjustments,
      pendingWithdrawals: pendingWithdrawals ?? this.pendingWithdrawals,
      action: identical(action, _unchanged)
          ? this.action
          : action as AdminOperationsAction?,
      actionTargetId: identical(actionTargetId, _unchanged)
          ? this.actionTargetId
          : actionTargetId as int?,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
