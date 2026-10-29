import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/auth/session_invalidation_bus.dart';
import '../../../core/network/api_failure.dart';
import '../domain/app_user.dart';
import '../domain/auth_session.dart';
import 'session_state.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  StreamSubscription<SessionInvalidationReason>? _invalidationSubscription;
  Future<void>? _bootstrapFuture;

  @override
  SessionState build() {
    _invalidationSubscription ??= ref
        .read(sessionInvalidationBusProvider)
        .stream
        .listen((_) => unawaited(_invalidateSession()));
    ref.onDispose(() => _invalidationSubscription?.cancel());
    scheduleMicrotask(bootstrap);
    return const SessionBooting();
  }

  Future<void> bootstrap() {
    return _bootstrapFuture ??= _runBootstrap().whenComplete(() {
      _bootstrapFuture = null;
    });
  }

  Future<void> _runBootstrap() async {
    state = const SessionBooting();
    try {
      final token = await ref.read(tokenStoreProvider).read();
      if (token == null || token.isEmpty) {
        state = const SessionSignedOut();
        return;
      }
      final user = await ref.read(authRepositoryProvider).currentUser();
      if (!_isAllowedRole(user.role)) {
        await ref.read(tokenStoreProvider).clear();
        state = SessionSignedOut(failure: _roleMismatchFailure(user.role));
        return;
      }
      state = SessionSignedIn(AuthSession(accessToken: token, user: user));
    } on ApiFailure catch (failure) {
      if (failure.isUnauthorized) {
        await ref.read(tokenStoreProvider).clear();
        state = const SessionSignedOut();
      } else {
        state = SessionUnavailable(failure);
      }
    } catch (error) {
      state = SessionUnavailable(error);
    }
  }

  Future<void> signIn({
    required String identity,
    required String password,
  }) async {
    state = const SessionAuthenticating();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signIn(identity: identity, password: password);
      await _persistAndActivate(session);
    } on ApiFailure catch (failure) {
      state = SessionSignedOut(failure: failure);
    } catch (error) {
      state = SessionUnavailable(error);
    }
  }

  Future<void> activateRegisteredSession(AuthSession session) {
    state = const SessionAuthenticating();
    return _persistAndActivate(session);
  }

  Future<void> _persistAndActivate(AuthSession session) async {
    if (!_isAllowedRole(session.user.role)) {
      await ref.read(tokenStoreProvider).clear();
      state = SessionSignedOut(
        failure: _roleMismatchFailure(session.user.role),
      );
      return;
    }
    await ref.read(tokenStoreProvider).write(session.accessToken);
    state = SessionSignedIn(session);
  }

  bool _isAllowedRole(AppRole role) =>
      ref.read(runtimeAllowedRolesProvider).contains(role);

  ApiFailure _roleMismatchFailure(AppRole actualRole) {
    final allowedRoles = ref.read(runtimeAllowedRolesProvider);
    final providerOnly = isProviderOnlyRuntime(allowedRoles);
    return ApiFailure(
      kind: ApiFailureKind.forbidden,
      message: providerOnly
          ? 'Tài khoản này không phải tài khoản thợ. Vui lòng đăng nhập bằng tài khoản thợ.'
          : actualRole == AppRole.provider
          ? 'Tài khoản này dành cho thợ. Vui lòng mở ứng dụng REVO Thợ.'
          : 'Tài khoản không phù hợp với ứng dụng này.',
    );
  }

  Future<void> signOut() async {
    // Flip the session to signed-out first so any route guard reacts
    // immediately and never bounces a logging-out user back to a protected
    // route. The remote/token cleanup then runs best-effort.
    state = const SessionSignedOut();
    try {
      await ref.read(pushRegistrationServiceProvider).deactivate();
    } catch (_) {
      // Local token deletion still runs in the service even if the backend is unreachable.
    }
    await ref.read(tokenStoreProvider).clear();
  }

  Future<void> _invalidateSession() async {
    await ref.read(tokenStoreProvider).clear();
    state = const SessionSignedOut();
  }
}
