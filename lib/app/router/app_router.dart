import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/application/session_state.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/session_bootstrap_page.dart';
import '../../features/auth/presentation/session_error_page.dart';
import '../../features/auth/presentation/sign_in_integration_page.dart';
import '../../features/shell/presentation/role_integration_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(sessionControllerProvider);
  final router = GoRouter(
    initialLocation: _locationFor(sessionState),
    redirect: (context, state) {
      final target = _locationFor(sessionState);
      final location = state.matchedLocation;

      if (sessionState is SessionSignedIn) {
        final roleRoot = _roleLocation(sessionState.session.user.role);
        if (location == roleRoot || location.startsWith('$roleRoot/')) {
          return null;
        }
        return roleRoot;
      }
      return location == target ? null : target;
    },
    routes: [
      GoRoute(
        path: '/bootstrap',
        builder: (context, state) => const SessionBootstrapPage(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInIntegrationPage(),
      ),
      GoRoute(
        path: '/session-error',
        builder: (context, state) => const SessionErrorPage(),
      ),
      GoRoute(
        path: '/customer',
        builder: (context, state) =>
            const RoleIntegrationPage(role: AppRole.customer),
      ),
      GoRoute(
        path: '/provider',
        builder: (context, state) =>
            const RoleIntegrationPage(role: AppRole.provider),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            const RoleIntegrationPage(role: AppRole.admin),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

String _locationFor(SessionState state) {
  return switch (state) {
    SessionBooting() => '/bootstrap',
    SessionAuthenticating() || SessionSignedOut() => '/sign-in',
    SessionUnavailable() => '/session-error',
    SessionSignedIn(:final session) => _roleLocation(session.user.role),
  };
}

String _roleLocation(AppRole role) {
  return switch (role) {
    AppRole.customer => '/customer',
    AppRole.provider => '/provider',
    AppRole.admin => '/admin',
  };
}
