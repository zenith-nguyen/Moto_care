import '../../orders/domain/geo_point.dart';

enum ProviderLocationMode { offline, waiting, activeOrder }

enum ProviderLocationAction {
  goOnline,
  trackOrder,
  resumeWaiting,
  sendNow,
  goOffline,
}

class ProviderLocationTrackingState {
  const ProviderLocationTrackingState({
    this.mode = ProviderLocationMode.offline,
    this.orderId,
    this.lastLocation,
    this.lastSentAt,
    this.action,
    this.lastFailure,
  });

  final ProviderLocationMode mode;
  final int? orderId;
  final GeoPoint? lastLocation;
  final DateTime? lastSentAt;
  final ProviderLocationAction? action;
  final Object? lastFailure;

  bool get isBusy => action != null;
  bool get isTracking => mode != ProviderLocationMode.offline;

  ProviderLocationTrackingState copyWith({
    ProviderLocationMode? mode,
    Object? orderId = _unchanged,
    GeoPoint? lastLocation,
    DateTime? lastSentAt,
    Object? action = _unchanged,
    Object? lastFailure = _unchanged,
  }) {
    return ProviderLocationTrackingState(
      mode: mode ?? this.mode,
      orderId: identical(orderId, _unchanged) ? this.orderId : orderId as int?,
      lastLocation: lastLocation ?? this.lastLocation,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      action: identical(action, _unchanged)
          ? this.action
          : action as ProviderLocationAction?,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
