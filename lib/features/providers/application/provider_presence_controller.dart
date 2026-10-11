import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/realtime/realtime_session_coordinator.dart';
import '../../orders/domain/geo_point.dart';
import 'provider_presence_state.dart';

final providerPresenceControllerProvider =
    AsyncNotifierProvider<ProviderPresenceController, ProviderPresenceState>(
      ProviderPresenceController.new,
    );

class ProviderPresenceController extends AsyncNotifier<ProviderPresenceState> {
  @override
  Future<ProviderPresenceState> build() async {
    return const ProviderPresenceState();
  }

  Future<void> updateWaitingLocation(GeoPoint location) async {
    await _run(ProviderPresenceAction.updateLocation, () async {
      final presence = await ref
          .read(providersRepositoryProvider)
          .updateWaitingLocation(location);
      state = AsyncData(_requireState().copyWith(presence: presence));
    });
  }

  Future<void> setOnline(bool isOnline) async {
    await _run(ProviderPresenceAction.setOnline, () async {
      final presence = await ref
          .read(providersRepositoryProvider)
          .setOnline(isOnline);
      state = AsyncData(_requireState().copyWith(presence: presence));
      ref.read(realtimeSessionCoordinatorProvider).refreshRoomMembership();
    });
  }

  Future<void> _run(
    ProviderPresenceAction action,
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

  ProviderPresenceState _requireState() {
    return state.value ??
        (throw StateError('Provider presence is not initialized.'));
  }
}
