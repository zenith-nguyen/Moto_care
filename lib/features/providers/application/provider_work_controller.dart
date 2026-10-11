import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/realtime/realtime_event.dart';
import '../../../core/realtime/realtime_session_coordinator.dart';
import '../../orders/domain/geo_point.dart';
import '../../orders/domain/order_models.dart';
import '../../orders/domain/order_status.dart';
import '../domain/provider_models.dart';
import 'provider_work_state.dart';

final providerWorkControllerProvider =
    AsyncNotifierProvider<ProviderWorkController, ProviderWorkState>(
      ProviderWorkController.new,
    );

class ProviderWorkController extends AsyncNotifier<ProviderWorkState> {
  StreamSubscription<RealtimeEvent>? _eventSubscription;
  StreamSubscription? _resyncSubscription;
  Future<void>? _silentRefresh;

  @override
  Future<ProviderWorkState> build() async {
    final realtime = ref.watch(realtimeClientProvider);
    final realtimeCoordinator = ref.read(realtimeSessionCoordinatorProvider);
    _eventSubscription = realtime.events.listen(_handleRealtimeEvent);
    _resyncSubscription = realtime.resyncRequests.listen((request) {
      if (request.refreshPendingOffers) unawaited(_refreshSilently());
    });
    ref.onDispose(() {
      unawaited(_eventSubscription?.cancel());
      unawaited(_resyncSubscription?.cancel());
      realtimeCoordinator.leaveOrder();
    });

    final offersFuture = ref
        .read(providersRepositoryProvider)
        .listPendingOffers();
    final ordersFuture = ref.read(ordersRepositoryProvider).listMine();
    return ProviderWorkState(
      pendingOffers: await offersFuture,
      orders: await ordersFuture,
    );
  }

  Future<void> refresh() async {
    await _run(ProviderWorkAction.refresh, _reloadListsAndSelected);
  }

  Future<void> selectOrder(int orderId) async {
    await _run(ProviderWorkAction.selectOrder, () async {
      final selected = await ref
          .read(ordersRepositoryProvider)
          .getById(orderId);
      state = AsyncData(_requireState().copyWith(selectedOrder: selected));
      ref.read(realtimeSessionCoordinatorProvider).followOrder(orderId);
    });
  }

  void clearSelectedOrder() {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(current.copyWith(selectedOrder: null));
    ref.read(realtimeSessionCoordinatorProvider).leaveOrder();
  }

  Future<void> acceptOffer(PendingOffer offer) async {
    await _run(ProviderWorkAction.acceptOffer, () async {
      await ref
          .read(ordersRepositoryProvider)
          .acceptOffer(orderId: offer.orderId, offerId: offer.id);
      final detailsFuture = ref
          .read(ordersRepositoryProvider)
          .getById(offer.orderId);
      final listsFuture = _loadLists();
      final details = await detailsFuture;
      final lists = await listsFuture;
      state = AsyncData(
        _requireState().copyWith(
          pendingOffers: lists.offers,
          orders: lists.orders,
          selectedOrder: details,
        ),
      );
      ref.read(realtimeSessionCoordinatorProvider).followOrder(offer.orderId);
    });
  }

  Future<void> rejectOffer(PendingOffer offer) async {
    await _run(ProviderWorkAction.rejectOffer, () async {
      await ref
          .read(ordersRepositoryProvider)
          .rejectOffer(orderId: offer.orderId, offerId: offer.id);
      final lists = await _loadLists();
      state = AsyncData(
        _requireState().copyWith(
          pendingOffers: lists.offers,
          orders: lists.orders,
        ),
      );
    });
  }

  Future<void> updateOrderLocation(GeoPoint location) async {
    await _withSelected(ProviderWorkAction.updateOrderLocation, (
      orderId,
    ) async {
      await ref
          .read(providersRepositoryProvider)
          .updateOrderLocation(orderId: orderId, location: location);
    });
  }

  Future<void> markArrived() async {
    await _withSelected(ProviderWorkAction.markArrived, (orderId) async {
      await ref.read(ordersRepositoryProvider).markArrived(orderId);
      await _reloadListsAndSelected();
    });
  }

  Future<void> startService(String token) async {
    await _withSelected(ProviderWorkAction.startService, (orderId) async {
      await ref
          .read(ordersRepositoryProvider)
          .startService(orderId: orderId, token: token);
      await _reloadListsAndSelected();
    });
  }

  Future<void> proposeFinalPrice({
    required String finalPrice,
    required String reason,
  }) async {
    await _withSelected(ProviderWorkAction.proposeFinalPrice, (orderId) async {
      await ref
          .read(ordersRepositoryProvider)
          .proposeFinalPrice(
            orderId: orderId,
            finalPrice: finalPrice,
            reason: reason,
          );
      await _reloadListsAndSelected();
    });
  }

  Future<void> disputeFinalPrice(String reason) async {
    final proposalId = state.value?.selectedOrder?.priceProposal?.id;
    if (proposalId == null) return;
    await _withSelected(ProviderWorkAction.disputeFinalPrice, (orderId) async {
      await ref
          .read(ordersRepositoryProvider)
          .disputeFinalPrice(
            orderId: orderId,
            proposalId: proposalId,
            reason: reason,
          );
      await _reloadListsAndSelected();
    });
  }

  Future<void> completeService() async {
    await _withSelected(ProviderWorkAction.completeService, (orderId) async {
      await ref.read(ordersRepositoryProvider).completeService(orderId);
      await _reloadListsAndSelected();
    });
  }

  Future<void> _withSelected(
    ProviderWorkAction action,
    Future<void> Function(int orderId) operation,
  ) async {
    final orderId = state.value?.selectedOrder?.id;
    if (orderId == null) return;
    await _run(action, () => operation(orderId));
  }

  Future<void> _run(
    ProviderWorkAction action,
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

  Future<void> _reloadListsAndSelected() async {
    final current = _requireState();
    final listsFuture = _loadLists();
    final selectedFuture = current.selectedOrder == null
        ? null
        : ref.read(ordersRepositoryProvider).getById(current.selectedOrder!.id);
    final lists = await listsFuture;
    state = AsyncData(
      _requireState().copyWith(
        pendingOffers: lists.offers,
        orders: lists.orders,
        selectedOrder: selectedFuture == null ? null : await selectedFuture,
      ),
    );
  }

  Future<({List<PendingOffer> offers, List<OrderSummary> orders})>
  _loadLists() async {
    final offersFuture = ref
        .read(providersRepositoryProvider)
        .listPendingOffers();
    final ordersFuture = ref.read(ordersRepositoryProvider).listMine();
    return (offers: await offersFuture, orders: await ordersFuture);
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    switch (event) {
      case OfferCreated() || OfferExpired():
        unawaited(_refreshSilently());
      case OrderStatusChanged(:final orderId, :final status):
        final current = state.value;
        final selected = current?.selectedOrder;
        if (current != null && selected?.id == orderId) {
          try {
            state = AsyncData(
              current.copyWith(
                selectedOrder: selected!.copyWith(
                  status: OrderStatus.fromWire(status),
                ),
              ),
            );
          } on FormatException {
            // REST refresh below remains the source of truth.
          }
        }
        unawaited(_refreshSilently());
      case ProviderLocationUpdated() || MessageCreated():
        break;
    }
  }

  Future<void> _refreshSilently() {
    return _silentRefresh ??= _runSilentRefresh().whenComplete(() {
      _silentRefresh = null;
    });
  }

  Future<void> _runSilentRefresh() async {
    if (state.value == null || state.value!.isBusy) return;
    try {
      await _reloadListsAndSelected();
    } catch (_) {
      // Keep the last valid snapshot; explicit refresh exposes the failure.
    }
  }

  ProviderWorkState _requireState() {
    return state.value ?? (throw StateError('Provider work is not loaded.'));
  }
}
