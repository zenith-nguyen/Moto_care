import 'dart:async';

enum SessionInvalidationReason { unauthorized }

class SessionInvalidationBus {
  final _controller = StreamController<SessionInvalidationReason>.broadcast(
    sync: true,
  );

  Stream<SessionInvalidationReason> get stream => _controller.stream;

  void invalidate(SessionInvalidationReason reason) {
    if (!_controller.isClosed) _controller.add(reason);
  }

  Future<void> dispose() => _controller.close();
}
