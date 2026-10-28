import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/device/device_location_source.dart';
import '../../../core/realtime/realtime_session_coordinator.dart';
import '../../orders/domain/geo_point.dart';
import 'provider_location_tracking_state.dart';

const providerWaitingLocationInterval = Duration(seconds: 45);
const providerActiveOrderLocationInterval = Duration(seconds: 5);

final providerLocationTrackingControllerProvider =
    AsyncNotifierProvider.autoDispose<
      ProviderLocationTrackingController,
      ProviderLocationTrackingState
    >(ProviderLocationTrackingController.new);

class ProviderLocationTrackingController
    extends AsyncNotifier<ProviderLocationTrackingState> {
  Timer? _timer;
  Future<void>? _scheduledSync;

  @override
  Future<ProviderLocationTrackingState> build() async {
    // Availability and GPS heartbeat must survive tab/screen rebuilds. If
    // this auto-disposed controller is recreated, the UI falls back to OFF
    // even though the backend still has the provider online.
    ref.keepAlive();
    ref.onDispose(_cancelTimer);
    return const ProviderLocationTrackingState();
  }

  Future<void> goOnline() async {
    await _run(ProviderLocationAction.goOnline, () async {
      _cancelTimer();
      await _drainScheduledSync();
      final point = await _sendWaitingLocation();
      await ref.read(providersRepositoryProvider).setOnline(true);
      ref.read(realtimeSessionCoordinatorProvider).refreshRoomMembership();
      state = AsyncData(
        _requireState().copyWith(
          mode: ProviderLocationMode.waiting,
          orderId: null,
          lastLocation: point,
          lastSentAt: DateTime.now().toUtc(),
        ),
      );
      _schedule(providerWaitingLocationInterval);
    });
  }

  Future<void> trackOrder(int orderId) async {
    if (orderId <= 0) throw ArgumentError.value(orderId, 'orderId');
    await _run(ProviderLocationAction.trackOrder, () async {
      _cancelTimer();
      await _drainScheduledSync();
      final point = await _sendOrderLocation(orderId);
      state = AsyncData(
        _requireState().copyWith(
          mode: ProviderLocationMode.activeOrder,
          orderId: orderId,
          lastLocation: point,
          lastSentAt: DateTime.now().toUtc(),
        ),
      );
      _schedule(providerActiveOrderLocationInterval);
    });
  }

  Future<void> resumeWaiting() async {
    await _run(ProviderLocationAction.resumeWaiting, () async {
      _cancelTimer();
      await _drainScheduledSync();
      final point = await _sendWaitingLocation();
      state = AsyncData(
        _requireState().copyWith(
          mode: ProviderLocationMode.waiting,
          orderId: null,
          lastLocation: point,
          lastSentAt: DateTime.now().toUtc(),
        ),
      );
      _schedule(providerWaitingLocationInterval);
    });
  }

  Future<void> sendNow() async {
    await _run(ProviderLocationAction.sendNow, () async {
      final current = _requireState();
      final GeoPoint point;
      switch (current.mode) {
        case ProviderLocationMode.offline:
          throw StateError('Location tracking is offline.');
        case ProviderLocationMode.waiting:
          point = await _sendWaitingLocation();
        case ProviderLocationMode.activeOrder:
          final orderId = current.orderId;
          if (orderId == null) throw StateError('Active order is missing.');
          point = await _sendOrderLocation(orderId);
      }
      state = AsyncData(
        _requireState().copyWith(
          lastLocation: point,
          lastSentAt: DateTime.now().toUtc(),
        ),
      );
    });
  }

  Future<void> goOffline() async {
    await _run(ProviderLocationAction.goOffline, () async {
      _cancelTimer();
      await _drainScheduledSync();
      await ref.read(providersRepositoryProvider).setOnline(false);
      ref.read(realtimeSessionCoordinatorProvider).refreshRoomMembership();
      state = AsyncData(
        _requireState().copyWith(
          mode: ProviderLocationMode.offline,
          orderId: null,
        ),
      );
    });
  }

  Future<void> openRecoverySettings() async {
    final location = ref.read(deviceLocationSourceProvider);
    final failure = state.value?.lastFailure;
    if (failure is DeviceLocationException &&
        failure.kind == DeviceLocationFailureKind.serviceDisabled) {
      await location.openLocationSettings();
    } else {
      await location.openAppSettings();
    }
  }

  Future<GeoPoint> _sendWaitingLocation() async {
    final point = await ref
        .read(deviceLocationSourceProvider)
        .currentLocation();
    await ref.read(providersRepositoryProvider).updateWaitingLocation(point);
    return point;
  }

  Future<GeoPoint> _sendOrderLocation(int orderId) async {
    final point = await ref
        .read(deviceLocationSourceProvider)
        .currentLocation();
    await ref
        .read(providersRepositoryProvider)
        .updateOrderLocation(orderId: orderId, location: point);
    return point;
  }

  void _schedule(Duration interval) {
    _timer = Timer.periodic(interval, (_) {
      _scheduledSync ??= _syncSilently().whenComplete(() {
        _scheduledSync = null;
      });
    });
  }

  Future<void> _syncSilently() async {
    final current = state.value;
    if (current == null || current.isBusy || !current.isTracking) return;
    try {
      final point = switch (current.mode) {
        ProviderLocationMode.waiting => await _sendWaitingLocation(),
        ProviderLocationMode.activeOrder => await _sendOrderLocation(
          current.orderId ?? (throw StateError('Active order is missing.')),
        ),
        ProviderLocationMode.offline => null,
      };
      if (point != null && state.value != null) {
        state = AsyncData(
          state.value!.copyWith(
            lastLocation: point,
            lastSentAt: DateTime.now().toUtc(),
            lastFailure: null,
          ),
        );
      }
    } catch (error) {
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(lastFailure: error));
      }
    }
  }

  Future<void> _run(
    ProviderLocationAction action,
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

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _drainScheduledSync() async {
    await _scheduledSync;
  }

  ProviderLocationTrackingState _requireState() {
    return state.value ??
        (throw StateError('Provider location tracking is not initialized.'));
  }
}
