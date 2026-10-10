import '../domain/provider_models.dart';

enum ProviderPresenceAction { updateLocation, setOnline }

class ProviderPresenceState {
  const ProviderPresenceState({this.presence, this.action, this.lastFailure});

  final ProviderPresence? presence;
  final ProviderPresenceAction? action;
  final Object? lastFailure;

  bool get isBusy => action != null;

  ProviderPresenceState copyWith({
    Object? presence = _unchanged,
    Object? action = _unchanged,
    Object? lastFailure = _unchanged,
  }) {
    return ProviderPresenceState(
      presence: identical(presence, _unchanged)
          ? this.presence
          : presence as ProviderPresence?,
      action: identical(action, _unchanged)
          ? this.action
          : action as ProviderPresenceAction?,
      lastFailure: identical(lastFailure, _unchanged)
          ? this.lastFailure
          : lastFailure,
    );
  }
}

const _unchanged = Object();
