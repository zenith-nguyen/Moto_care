import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'realtime_transport.dart';

class SocketIoRealtimeTransport implements RealtimeTransport {
  static const eventNames = <String>{
    'offer.created',
    'offer.expired',
    'order.status_changed',
    'provider.location_updated',
    'message.created',
  };

  final StreamController<RealtimeTransportEvent> _events =
      StreamController<RealtimeTransportEvent>.broadcast(sync: true);
  socket_io.Socket? _socket;
  bool _hasConnected = false;

  @override
  Stream<RealtimeTransportEvent> get events => _events.stream;

  @override
  void connect({required Uri origin, required Map<String, Object> auth}) {
    disconnect();
    _hasConnected = false;

    final socket = socket_io.io(
      origin.toString(),
      socket_io.OptionBuilder()
          .setTransports(const ['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(10000)
          .setAuth(auth)
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      final isReconnect = _hasConnected;
      _hasConnected = true;
      _add(RealtimeTransportConnected(isReconnect: isReconnect));
    });
    socket.onReconnectAttempt((_) {
      _add(const RealtimeTransportReconnecting());
    });
    socket.onDisconnect((_) {
      _add(const RealtimeTransportDisconnected());
    });
    socket.onConnectError((_) {
      _add(const RealtimeTransportFailed());
    });
    socket.onReconnectFailed((_) {
      _add(const RealtimeTransportFailed());
    });
    for (final name in eventNames) {
      socket.on(name, (data) {
        _add(RealtimeTransportPayload(name, data));
      });
    }
    socket.connect();
  }

  @override
  void disconnect() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket.clearListeners();
    socket.disconnect();
    socket.dispose();
  }

  @override
  Future<void> dispose() async {
    disconnect();
    await _events.close();
  }

  void _add(RealtimeTransportEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}
