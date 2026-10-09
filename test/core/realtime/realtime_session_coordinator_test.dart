import 'package:flutter_test/flutter_test.dart';
import 'package:moto_care/core/realtime/realtime_client.dart';
import 'package:moto_care/core/realtime/realtime_session_coordinator.dart';
import 'package:moto_care/features/auth/application/session_state.dart';
import 'package:moto_care/features/auth/domain/app_user.dart';
import 'package:moto_care/features/auth/domain/auth_session.dart';

void main() {
  test('connects by authenticated role and reconnects for an order room', () {
    final connection = FakeRealtimeConnection();
    final coordinator = RealtimeSessionCoordinator(
      connection,
      Uri.parse('https://demo.example.test'),
    );

    coordinator.synchronize(
      SessionSignedIn(
        AuthSession(
          accessToken: 'provider-jwt',
          user: user(role: AppRole.provider),
        ),
      ),
    );
    coordinator.followOrder(73);

    expect(connection.calls, hasLength(2));
    expect(connection.calls.first.scope.orderId, isNull);
    expect(connection.calls.last.scope.orderId, 73);
    expect(connection.calls.last.scope.role, AppRole.provider);
  });

  test('logout disconnects and removes remembered order scope', () {
    final connection = FakeRealtimeConnection();
    final coordinator = RealtimeSessionCoordinator(
      connection,
      Uri.parse('https://demo.example.test'),
    );
    final session = AuthSession(
      accessToken: 'customer-jwt',
      user: user(role: AppRole.customer),
    );

    coordinator.synchronize(SessionSignedIn(session));
    coordinator.followOrder(73);
    coordinator.synchronize(const SessionSignedOut());
    coordinator.synchronize(SessionSignedIn(session));

    expect(connection.disconnectCount, 1);
    expect(connection.calls.last.scope.orderId, isNull);
  });

  test('refreshes provider room membership after online status changes', () {
    final connection = FakeRealtimeConnection();
    final coordinator = RealtimeSessionCoordinator(
      connection,
      Uri.parse('https://demo.example.test'),
    );
    coordinator.synchronize(
      SessionSignedIn(
        AuthSession(
          accessToken: 'provider-jwt',
          user: user(role: AppRole.provider),
        ),
      ),
    );

    coordinator.refreshRoomMembership();

    expect(connection.calls, hasLength(2));
  });
}

AppUser user({required AppRole role}) {
  return AppUser(
    id: 1,
    name: 'Realtime Test',
    email: 'test@example.com',
    phone: null,
    role: role,
    status: AppUserStatus.active,
  );
}

class ConnectionCall {
  const ConnectionCall({
    required this.origin,
    required this.accessToken,
    required this.scope,
  });

  final Uri origin;
  final String accessToken;
  final RealtimeScope scope;
}

class FakeRealtimeConnection implements RealtimeConnection {
  final List<ConnectionCall> calls = [];
  int disconnectCount = 0;

  @override
  void connect({
    required Uri origin,
    required String accessToken,
    required RealtimeScope scope,
  }) {
    calls.add(
      ConnectionCall(origin: origin, accessToken: accessToken, scope: scope),
    );
  }

  @override
  void disconnect() {
    disconnectCount += 1;
  }
}
