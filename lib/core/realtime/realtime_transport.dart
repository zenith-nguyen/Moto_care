sealed class RealtimeTransportEvent {
  const RealtimeTransportEvent();
}

class RealtimeTransportConnected extends RealtimeTransportEvent {
  const RealtimeTransportConnected({required this.isReconnect});

  final bool isReconnect;
}

class RealtimeTransportReconnecting extends RealtimeTransportEvent {
  const RealtimeTransportReconnecting();
}

class RealtimeTransportDisconnected extends RealtimeTransportEvent {
  const RealtimeTransportDisconnected();
}

class RealtimeTransportFailed extends RealtimeTransportEvent {
  const RealtimeTransportFailed();
}

class RealtimeTransportPayload extends RealtimeTransportEvent {
  const RealtimeTransportPayload(this.name, this.data);

  final String name;
  final Object? data;
}

abstract interface class RealtimeTransport {
  Stream<RealtimeTransportEvent> get events;

  void connect({required Uri origin, required Map<String, Object> auth});

  void disconnect();

  Future<void> dispose();
}
