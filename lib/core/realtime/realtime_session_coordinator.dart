import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_dependencies.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/application/session_state.dart';
import '../../features/auth/domain/auth_session.dart';
import 'realtime_client.dart';

final realtimeSessionCoordinatorProvider = Provider<RealtimeSessionCoordinator>(
  (ref) {
    final coordinator = RealtimeSessionCoordinator(
      ref.watch(realtimeClientProvider),
      ref.watch(appConfigProvider).apiBaseUri,
    );
    ref.listen<SessionState>(sessionControllerProvider, (_, next) {
      coordinator.synchronize(next);
    }, fireImmediately: true);
    ref.onDispose(coordinator.dispose);
    return coordinator;
  },
);

class RealtimeSessionCoordinator {
  RealtimeSessionCoordinator(this._connection, this._origin);

  final RealtimeConnection _connection;
  final Uri _origin;
  AuthSession? _session;
  int? _orderId;

  void synchronize(SessionState state) {
    if (state case SessionSignedIn(:final session)) {
      final unchanged =
          _session?.accessToken == session.accessToken &&
          _session?.user.role == session.user.role;
      _session = session;
      if (!unchanged) _connect();
      return;
    }

    _session = null;
    _orderId = null;
    _connection.disconnect();
  }

  void followOrder(int orderId) {
    if (orderId <= 0) throw ArgumentError.value(orderId, 'orderId');
    if (_orderId == orderId) return;
    _orderId = orderId;
    _connect();
  }

  void leaveOrder() {
    if (_orderId == null) return;
    _orderId = null;
    _connect();
  }

  void refreshRoomMembership() {
    _connect();
  }

  void dispose() {
    _session = null;
    _orderId = null;
    _connection.disconnect();
  }

  void _connect() {
    final session = _session;
    if (session == null) return;
    _connection.connect(
      origin: _origin,
      accessToken: session.accessToken,
      scope: RealtimeScope(role: session.user.role, orderId: _orderId),
    );
  }
}
