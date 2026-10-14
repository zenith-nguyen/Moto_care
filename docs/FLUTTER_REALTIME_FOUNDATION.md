# Flutter realtime foundation

This layer gives Customer, Provider, and Admin UI one authenticated Socket.IO
connection without putting transport code in widgets. REST remains the source
of truth; realtime events only tell feature controllers what changed quickly.

## Connection lifecycle

- `RealtimeSessionCoordinator` connects after the server-confirmed session is
  signed in and disconnects immediately on logout or REST session invalidation.
- The handshake uses `auth: { token, orderId? }`. The JWT is never placed in the
  URL, query string, log output, widget state, or a public configuration value.
- The transport uses the same validated `API_BASE_URL` origin as Dio. HTTPS
  therefore becomes WSS automatically for release/demo traffic.
- `followOrder(orderId)` reconnects with that order scope. The backend admits
  only the Customer or assigned Provider to `order:{orderId}`.
- `leaveOrder()` returns to the session-only connection.
- A Provider must call `refreshRoomMembership()` after a successful online/offline
  update. The backend joins `provider:{providerId}` only when the account is
  approved and currently online.

Explicit disconnect clears listeners and the active order scope. The Socket.IO
adapter owns reconnect backoff (1–5 seconds); feature code must not create a
second socket or retry business commands automatically.

## Typed event contract

| Backend event | Flutter model | Scope |
| --- | --- | --- |
| `offer.created` | `OfferCreated` | approved online Provider |
| `offer.expired` | `OfferExpired` | approved online Provider |
| `order.status_changed` | `OrderStatusChanged` | current order participant |
| `provider.location_updated` | `ProviderLocationUpdated` | current order participant |
| `message.created` | `MessageCreated` | current order participant |

`RealtimeClient` validates IDs, timestamps, coordinates, image metadata, role,
and active `orderId`. Unknown, malformed, wrong-role, and wrong-order payloads
are ignored rather than reaching UI state. Protected chat image URLs may be
relative API paths and must still be downloaded through authenticated Dio.

## REST resynchronization

Every successful connection emits `RealtimeResyncRequest`, including the first
connection and every reconnect. A feature integration reacts as follows:

- Provider: reload `GET /providers/me/offers/pending`.
- Active order: reload `GET /orders/:orderId` and
  `GET /orders/:orderId/messages`.
- Replace local snapshots with REST results, then continue applying newer typed
  events.

This foundation emits the request; role repositories/controllers added in the
next milestones perform the HTTP calls. It intentionally does not replay
accept/reject/payment/message/GPS commands after a connection loss because
those commands need explicit idempotency and user intent.

## UI integration API

Use Riverpod dependencies instead of importing Socket.IO in a screen:

```dart
final realtime = ref.read(realtimeClientProvider);
final rooms = ref.read(realtimeSessionCoordinatorProvider);

rooms.followOrder(orderId);
realtime.events.listen((event) {
  // Forward typed events into the feature controller.
});
```

Feature controllers own subscriptions and cancel them on dispose. A screen
leaving the tracked order calls `leaveOrder()`. Do not show “connected” as proof
that a payment or order transition succeeded; only the corresponding REST
snapshot confirms durable state.

## Verification

Tests cover handshake placement, all five payloads, malformed/wrong-order
filtering, initial/reconnect resync, provider room refresh, and logout cleanup.

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```
