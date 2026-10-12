import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_dependencies.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/application/session_state.dart';
import 'push_registration_service.dart';

final pushSessionCoordinatorProvider = Provider<PushSessionCoordinator>((ref) {
  final coordinator = PushSessionCoordinator(
    ref.watch(pushRegistrationServiceProvider),
  );
  ref.listen<SessionState>(sessionControllerProvider, (_, next) {
    coordinator.synchronize(next);
  }, fireImmediately: true);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

class PushSessionCoordinator {
  PushSessionCoordinator(this._registration);

  final PushRegistrationService _registration;
  bool _signedIn = false;

  void synchronize(SessionState state) {
    final signedIn = state is SessionSignedIn;
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    if (signedIn) {
      _safely(_registration.activate());
    } else {
      _safely(_registration.deactivate());
    }
  }

  void dispose() {
    _safely(_registration.dispose());
  }

  void _safely(Future<void> action) {
    unawaited(action.catchError((_) {}));
  }
}
