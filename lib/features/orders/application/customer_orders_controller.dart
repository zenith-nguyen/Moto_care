import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/realtime/realtime_event.dart';
import '../../../core/realtime/realtime_session_coordinator.dart';
import '../domain/geo_point.dart';
import '../domain/order_status.dart';
import 'customer_orders_state.dart';

final customerOrdersControllerProvider =
    AsyncNotifierProvider<CustomerOrdersController, CustomerOrdersState>(
      CustomerOrdersController.new,
    );

class CustomerOrdersController extends AsyncNotifier<CustomerOrdersState> {
  StreamSubscription<RealtimeEvent>? _eventSubscription;
  StreamSubscription? _resyncSubscription;
  Future<void>? _detailRefresh;

  @override
  Future<CustomerOrdersState> build() async {
    final realtime = ref.watch(realtimeClientProvider);
    final realtimeCoordinator = ref.read(realtimeSessionCoordinatorProvider);
    _eventSubscription = realtime.events.listen(_handleRealtimeEvent);
    _resyncSubscription = realtime.resyncRequests.listen((request) {
      final selectedId = state.value?.selectedOrder?.id;
      if (selectedId != null && request.orderId == selectedId) {
        unawaited(_refreshSelectedSilently());
      }
    });
    ref.onDispose(() {
      unawaited(_eventSubscription?.cancel());
      unawaited(_resyncSubscription?.cancel());
      realtimeCoordinator.leaveOrder();
    });

    final incidentsFuture = ref
        .read(incidentTypesRepositoryProvider)
        .listActive();
    final ordersFuture = ref.read(ordersRepositoryProvider).listMine();
    return CustomerOrdersState(
      incidentTypes: await incidentsFuture,
      orders: await ordersFuture,
    );
  }

  Future<void> refreshAll() async {
    await _runAction(CustomerOrderAction.refresh, () async {
      final current = _requireState();
      final incidentsFuture = ref
          .read(incidentTypesRepositoryProvider)
          .listActive();
      final ordersFuture = ref.read(ordersRepositoryProvider).listMine();
      final selectedFuture = current.selectedOrder == null
          ? null
          : ref
                .read(ordersRepositoryProvider)
                .getById(current.selectedOrder!.id);
      state = AsyncData(
        current.copyWith(
          incidentTypes: await incidentsFuture,
          orders: await ordersFuture,
          selectedOrder: selectedFuture == null ? null : await selectedFuture,
          transferInstructions: null,
          serviceStartToken: null,
        ),
      );
    });
  }

  Future<void> selectOrder(int orderId) async {
    await _runAction(CustomerOrderAction.select, () async {
      final details = await ref.read(ordersRepositoryProvider).getById(orderId);
      state = AsyncData(
        _requireState().copyWith(
          selectedOrder: details,
          transferInstructions: null,
          serviceStartToken: null,
        ),
      );
      ref.read(realtimeSessionCoordinatorProvider).followOrder(orderId);
    });
  }

  void clearSelectedOrder() {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(
      current.copyWith(
        selectedOrder: null,
        transferInstructions: null,
        serviceStartToken: null,
      ),
    );
    ref.read(realtimeSessionCoordinatorProvider).leaveOrder();
  }

  Future<void> createOrder({
    required int incidentTypeId,
    required GeoPoint customerLocation,
  }) async {
    await _runAction(CustomerOrderAction.create, () async {
      final repository = ref.read(ordersRepositoryProvider);
      final created = await repository.create(
        incidentTypeId: incidentTypeId,
        customerLocation: customerLocation,
      );
      final detailsFuture = repository.getById(created.id);
      final ordersFuture = repository.listMine();
      final details = await detailsFuture;
      state = AsyncData(
        _requireState().copyWith(
          orders: await ordersFuture,
          selectedOrder: details,
          transferInstructions: null,
          serviceStartToken: null,
        ),
      );
      ref.read(realtimeSessionCoordinatorProvider).followOrder(created.id);
    });
  }

  Future<void> retryMatching() async {
    await _withSelectedOrder(CustomerOrderAction.retryMatching, (
      orderId,
    ) async {
      await ref.read(ordersRepositoryProvider).retryMatching(orderId);
      await _reloadOrderAndList(orderId);
    });
  }

  Future<void> cancelSelected(String reason) async {
    await _withSelectedOrder(CustomerOrderAction.cancel, (orderId) async {
      await ref.read(ordersRepositoryProvider).cancel(orderId, reason);
      await _reloadOrderAndList(orderId);
    });
  }

  Future<void> confirmDemoPrepayment() async {
    await _withSelectedOrder(CustomerOrderAction.confirmDemoPrepayment, (
      orderId,
    ) async {
      await ref.read(paymentsRepositoryProvider).confirmDemoPrepayment(orderId);
      await _reloadOrderAndList(orderId);
    });
  }

  Future<void> confirmDemoAdjustment() async {
    await _withSelectedOrder(CustomerOrderAction.confirmDemoAdjustment, (
      orderId,
    ) async {
      await ref.read(paymentsRepositoryProvider).confirmDemoAdjustment(orderId);
      await _reloadOrderAndList(orderId);
    });
  }

  Future<void> loadTestModeTransferInstructions() async {
    await _withSelectedOrder(CustomerOrderAction.loadTransferInstructions, (
      orderId,
    ) async {
      final instructions = await ref
          .read(paymentsRepositoryProvider)
          .getTestModeInstructions(orderId);
      state = AsyncData(
        _requireState().copyWith(transferInstructions: instructions),
      );
    });
  }

  Future<void> loadServiceStartToken() async {
    await _withSelectedOrder(CustomerOrderAction.loadStartToken, (
      orderId,
    ) async {
      final token = await ref
          .read(ordersRepositoryProvider)
          .getStartToken(orderId);
      state = AsyncData(_requireState().copyWith(serviceStartToken: token));
    });
  }

  Future<void> approveFinalPrice() async {
    final proposalId = state.value?.selectedOrder?.priceProposal?.id;
    if (proposalId == null) return;
    await _withSelectedOrder(CustomerOrderAction.approveFinalPrice, (
      orderId,
    ) async {
      await ref
          .read(ordersRepositoryProvider)
          .approveFinalPrice(orderId: orderId, proposalId: proposalId);
      await _reloadOrderAndList(orderId);
    });
  }

  Future<void> rejectFinalPrice(String reason) async {
    final proposalId = state.value?.selectedOrder?.priceProposal?.id;
    if (proposalId == null) return;
    await _withSelectedOrder(CustomerOrderAction.rejectFinalPrice, (
      orderId,
    ) async {
      await ref
          .read(ordersRepositoryProvider)
          .rejectFinalPrice(
            orderId: orderId,
            proposalId: proposalId,
            reason: reason,
          );
      await _reloadOrderAndList(orderId);
    });
  }

  Future<void> _withSelectedOrder(
    CustomerOrderAction action,
    Future<void> Function(int orderId) operation,
  ) async {
    final orderId = state.value?.selectedOrder?.id;
    if (orderId == null) return;
    await _runAction(action, () => operation(orderId));
  }

  Future<void> _runAction(
    CustomerOrderAction action,
    Future<void> Function() operation,
  ) async {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(current.copyWith(action: action, lastFailure: null));
    try {
      await operation();
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(action: null, lastFailure: null));
      }
    } catch (error) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(action: null, lastFailure: error));
    }
  }

  Future<void> _reloadOrderAndList(int orderId) async {
    final repository = ref.read(ordersRepositoryProvider);
    final detailsFuture = repository.getById(orderId);
    final ordersFuture = repository.listMine();
    state = AsyncData(
      _requireState().copyWith(
        selectedOrder: await detailsFuture,
        orders: await ordersFuture,
        transferInstructions: null,
        serviceStartToken: null,
      ),
    );
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    final current = state.value;
    final selected = current?.selectedOrder;
    if (current == null || selected == null || event.orderId != selected.id) {
      return;
    }
    switch (event) {
      case OrderStatusChanged(:final status):
        state = AsyncData(
          current.copyWith(
            selectedOrder: selected.copyWith(status: _orderStatus(status)),
          ),
        );
        unawaited(_refreshSelectedSilently());
      case ProviderLocationUpdated(:final latitude, :final longitude):
        state = AsyncData(
          current.copyWith(
            selectedOrder: selected.copyWith(
              providerLocation: GeoPoint(
                latitude: latitude,
                longitude: longitude,
              ),
            ),
          ),
        );
      case OfferCreated() || OfferExpired() || MessageCreated():
        break;
    }
  }

  Future<void> _refreshSelectedSilently() {
    return _detailRefresh ??= _runSilentDetailRefresh().whenComplete(() {
      _detailRefresh = null;
    });
  }

  Future<void> _runSilentDetailRefresh() async {
    final orderId = state.value?.selectedOrder?.id;
    if (orderId == null) return;
    try {
      final details = await ref.read(ordersRepositoryProvider).getById(orderId);
      final current = state.value;
      if (current?.selectedOrder?.id == orderId) {
        state = AsyncData(current!.copyWith(selectedOrder: details));
      }
    } catch (_) {
      // Keep the last valid snapshot. Explicit refresh exposes the failure.
    }
  }

  CustomerOrdersState _requireState() {
    final current = state.value;
    if (current == null) throw StateError('Customer orders are not loaded.');
    return current;
  }
}

OrderStatus _orderStatus(String wireValue) {
  return OrderStatus.fromWire(wireValue);
}
