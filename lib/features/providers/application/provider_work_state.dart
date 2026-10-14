import '../../orders/domain/order_models.dart';
import '../domain/provider_models.dart';

enum ProviderWorkAction {
  refresh,
  selectOrder,
  acceptOffer,
  rejectOffer,
  updateOrderLocation,
  markArrived,
  startService,
  proposeFinalPrice,
  disputeFinalPrice,
  completeService,
}

class ProviderWorkState {
  const ProviderWorkState({
    required this.pendingOffers,
    required this.orders,
    this.selectedOrder,
    this.action,
    this.lastFailure,
  });

  final List<PendingOffer> pendingOffers;
  final List<OrderSummary> orders;
  final OrderDetails? selectedOrder;
  final ProviderWorkAction? action;
  final Object? lastFailure;

  bool get isBusy => action != null;

  ProviderWorkState copyWith({
    List<PendingOffer>? pendingOffers,
    List<OrderSummary>? orders,
    Object? selectedOrder = _unchanged,
    Object? action = _unchanged,
    Object? lastFailure = _unchanged,
  }) {
    return ProviderWorkState(
      pendingOffers: pendingOffers ?? this.pendingOffers,
      orders: orders ?? this.orders,
      selectedOrder: identical(selectedOrder, _unchanged)
          ? this.selectedOrder
          : selectedOrder as OrderDetails?,
      action: identical(action, _unchanged)
          ? this.action
          : action as ProviderWorkAction?,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
