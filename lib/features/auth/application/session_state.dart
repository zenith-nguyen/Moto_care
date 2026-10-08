import '../../../core/network/api_failure.dart';
import '../domain/auth_session.dart';

sealed class SessionState {
  const SessionState();
}

class SessionBooting extends SessionState {
  const SessionBooting();
}

class SessionSignedOut extends SessionState {
  const SessionSignedOut({this.failure});

  final ApiFailure? failure;
}

class SessionAuthenticating extends SessionState {
  const SessionAuthenticating();
}

class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.session);

  final AuthSession session;
}

class SessionUnavailable extends SessionState {
  const SessionUnavailable(this.failure);

  final Object failure;
}
