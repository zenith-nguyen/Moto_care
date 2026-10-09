import '../../incidents/domain/incident_type.dart';
import '../../payments/domain/bank_transfer_instructions.dart';
import '../domain/order_models.dart';
import '../domain/order_action_results.dart';

enum CustomerOrderAction {
  create,
  select,
  refresh,
  retryMatching,
  cancel,
  confirmDemoPrepayment,
  confirmDemoAdjustment,
  loadTransferInstructions,
  loadStartToken,
  approveFinalPrice,
  rejectFinalPrice,
}

class CustomerOrdersState {
  const CustomerOrdersState({
    required this.incidentTypes,
    required this.orders,
    this.selectedOrder,
    this.transferInstructions,
    this.serviceStartToken,
    this.action,
    this.lastFailure,
  });

  final List<IncidentType> incidentTypes;
  final List<OrderSummary> orders;
  final OrderDetails? selectedOrder;
  final BankTransferInstructions? transferInstructions;
  final ServiceStartToken? serviceStartToken;
  final CustomerOrderAction? action;
  final Object? lastFailure;

  bool get isBusy => action != null;

  CustomerOrdersState copyWith({
    List<IncidentType>? incidentTypes,
    List<OrderSummary>? orders,
    Object? selectedOrder = _unchanged,
    Object? transferInstructions = _unchanged,
    Object? serviceStartToken = _unchanged,
    Object? action = _unchanged,
    Object? lastFailure = _unchanged,
  }) {
    return CustomerOrdersState(
      incidentTypes: incidentTypes ?? this.incidentTypes,
      orders: orders ?? this.orders,
      selectedOrder: identical(selectedOrder, _unchanged)
          ? this.selectedOrder
          : selectedOrder as OrderDetails?,
      transferInstructions: identical(transferInstructions, _unchanged)
          ? this.transferInstructions
          : transferInstructions as BankTransferInstructions?,
      serviceStartToken: identical(serviceStartToken, _unchanged)
          ? this.serviceStartToken
          : serviceStartToken as ServiceStartToken?,
      action: identical(action, _unchanged)
          ? this.action
          : action as CustomerOrderAction?,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
