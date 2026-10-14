# Flutter integration foundation

This foundation lets Customer, Provider, and Admin UI land incrementally without
duplicating HTTP, token, error, or routing logic. The current screens are
technical integration placeholders, not approved product UX.

## Runtime configuration

`API_BASE_URL` is a build-time public origin. It is not a secret and must not
contain credentials, a path, query parameters, or a fragment.

Android Emulator against the laptop backend:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Debug builds may use HTTP for local development. Release builds require an
explicit HTTPS origin:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://your-demo-origin.example
```

Do not use `localhost` in an APK installed on another device. `localhost` would
refer to that phone, not the development laptop.

## Shared boundaries

- `AppConfig` validates the API origin and rejects insecure release URLs.
- `ApiClient` owns Dio timeouts, Bearer injection, request IDs, response shape,
  and safe Vietnamese error mapping.
- `TokenStore` is implemented with `flutter_secure_storage`. Widgets never read
  or persist JWTs directly.
- A `401` clears the token and invalidates the application session. A `403`
  keeps the session and is presented as a permission failure.
- `SessionController` restores `/users/me`, signs users in/out, and exposes the
  server-confirmed role.
- `GoRouter` sends `CUSTOMER`, `PROVIDER`, and `ADMIN` to separate integration
  slots. UI teams replace slot contents, not the session/router foundation.
- API money is represented by `MoneyAmount`, which accepts only canonical
  non-negative decimal strings such as `"100000.00"`; no `double` arithmetic.

Repositories are injected with Riverpod. Feature widgets call repositories or
feature controllers; they do not create Dio instances or append JWT headers.

## SePay Test mode client boundary

`PaymentsRepository.getTestModeInstructions(orderId)` calls only:

```text
GET /payments/orders/:orderId/instructions
```

The model refuses a response unless all of these are true:

- `provider == "SEPAY"`
- `mode == "test"`
- `simulationOnly == true`
- `amount` is a canonical decimal string
- `qrImageUrl` uses HTTPS

Flutter never calls `/payments/webhooks/sepay` and never receives
`SEPAY_WEBHOOK_SECRET`. The payment screen must visibly label these instructions
as Test mode/simulation and poll the order REST snapshot after displaying the
QR. Live payment, bank refund, and bank withdrawal remain out of scope.

## UI handoff

When UI branches are ready:

1. Replace `SignInIntegrationPage` with the approved auth screens while keeping
   `SessionController.signIn` and its loading/error state.
2. Replace each `RoleIntegrationPage` route with the matching Customer,
   Provider, or Admin shell.
3. Keep role authorization server-side; client routing is navigation, not a
   security boundary.
4. Connect REST repositories first, then consume the shared Socket.IO client
   documented in [FLUTTER_REALTIME_FOUNDATION.md](FLUTTER_REALTIME_FOUNDATION.md).
   Realtime events never replace the REST snapshot/resync path.
5. Preserve loading, empty, offline, `409` refresh, `429` wait, and session-expiry
   states in every final screen.

## Verification

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

The foundation has tests for release URL safety, decimal money, auth payloads,
secure session lifecycle, Bearer/request-ID injection, `401` invalidation, role
state, and strict SePay Test mode parsing.
