abstract interface class PushTokenSource {
  bool get enabled;
  Stream<String> get tokenChanges;

  Future<String?> requestToken();
  Future<void> deleteToken();
}

class DisabledPushTokenSource implements PushTokenSource {
  const DisabledPushTokenSource();

  @override
  bool get enabled => false;

  @override
  Stream<String> get tokenChanges => const Stream.empty();

  @override
  Future<void> deleteToken() async {}

  @override
  Future<String?> requestToken() async => null;
}
