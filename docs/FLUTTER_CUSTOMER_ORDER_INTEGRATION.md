# Flutter Customer order integration

This layer exposes the Customer order workflow to the future team-owned UI.
It contains typed REST models, repositories, and one Riverpod controller; it
does not import or redesign Customer screens.

## Covered workflow

`CustomerOrdersController` currently coordinates:

1. Load the active incident catalog and the signed-in Customer's orders.
2. Create an order from an incident type and a validated latitude/longitude.
3. Load the durable order snapshot and follow `order:{orderId}` realtime scope.
4. Show the server-calculated base price, weather surcharge, multiplier,
   estimated price, payment state, provider location, and final-price state.
5. Retry matching or cancel an eligible order.
6. Load SePay **Test mode** transfer instructions.
7. Confirm demo prepayment or a demo final-price adjustment, then reload REST.

The backend remains the only authority for prices and state transitions.
Flutter never calculates a fare, weather surcharge, refund, or wallet amount.

## UI-facing providers

Use `customerOrdersControllerProvider` from a Consumer widget/controller:

```dart
final asyncState = ref.watch(customerOrdersControllerProvider);
final actions = ref.read(customerOrdersControllerProvider.notifier);
```

The loaded `CustomerOrdersState` contains:

- `incidentTypes`: quick choices for the create-order screen;
- `orders`: Customer order history/current list;
- `selectedOrder`: full REST snapshot for the tracking/detail screen;
- `transferInstructions`: SePay Test QR/transfer fields when requested;
- `action`: the single mutation currently in progress;
- `lastFailure`: safe error object for the UI error mapper.

Call `selectOrder(id)` when opening an order and `clearSelectedOrder()` when
leaving it. The controller owns and cancels realtime subscriptions. Widgets
must not create Socket.IO clients or keep their own JWT.

## Realtime and REST consistency

- `order.status_changed` updates the visible status quickly and triggers a REST
  refresh.
- `provider.location_updated` updates the selected order's provider marker.
- A reconnect/resync request reloads the selected order.
- REST is always the durable source of truth. Socket events are hints, not
  proof that payment or a business command succeeded.
- The controller does not automatically retry create/cancel/payment commands
  after network loss, which prevents duplicate business operations.

Provider location values are coordinates only. A future map widget may render
them with a free/no-key fallback, but it must not alter order state.

## Data safety rules

- Money is accepted only as canonical non-negative decimal strings through
  `MoneyAmount`; JSON floating-point money is rejected.
- GeoJSON is decoded as `[longitude, latitude]`, while create-order input is
  sent as `{latitude, longitude}` to match the backend DTO.
- All enum values are parsed strictly. An unknown backend state fails parsing
  instead of silently displaying the wrong Customer action.
- SePay instructions are accepted only when `mode=test` and
  `simulationOnly=true`. No webhook secret or bank credential belongs in APK.
- Only one controller action runs at a time. UI buttons should also disable
  while `state.isBusy` is true.

## API coverage in this milestone

| Method | Endpoint | Purpose |
| --- | --- | --- |
| GET | `/incident-types` | Active incident quick choices |
| GET | `/orders` | Customer order list |
| POST | `/orders` | Create order and price snapshot |
| GET | `/orders/:id` | Durable order/payment/GPS snapshot |
| POST | `/orders/:id/retry-match` | Retry provider matching |
| POST | `/orders/:id/cancel` | Cancel with a reason |
| GET | `/orders/:id/start-token` | Typed support for the later arrival UI |
| GET | `/payments/orders/:id/instructions` | SePay Test instructions |
| POST | `/payments/demo/orders/:id/confirm` | Confirm demo prepayment |
| POST | `/payments/demo/orders/:id/adjustment/confirm` | Confirm demo charge |

Customer chat/image history, final-price approve/reject, and reviews are the
next Customer integration slice. They will reuse this controller/repository
boundary rather than placing HTTP or multipart logic in widgets.

## Verification

Tests cover strict list/object parsing, money and coordinate validation, exact
request field names, payment Test-mode endpoints, controller orchestration,
realtime room selection, and reload-after-payment behavior.
