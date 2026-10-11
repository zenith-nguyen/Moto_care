# Flutter Provider integration

This document is the UI handoff contract for the provider application flow. The
data/application layer is independent from prototype widgets; UI code watches
the providers below instead of calling HTTP or Socket.IO directly.

## Ownership and boundaries

| Responsibility | Riverpod provider | Notes |
| --- | --- | --- |
| Availability and waiting GPS | `providerPresenceControllerProvider` | Location must be fresh before going online. |
| Offers and active service | `providerWorkControllerProvider` | REST is authoritative; realtime triggers resync. |
| Demo wallet and withdrawals | `providerWalletControllerProvider` | Sandbox ledger only; never label it as real money. |
| Chat and protected images | `customerChatControllerProvider(orderId)` | Participant-safe and reusable by Provider UI. |
| Reviews | `orderReviewsControllerProvider(orderId)` | Only for completed participant orders. |

Provider UI must not instantiate Dio, build authorization headers, parse
Socket.IO payloads, or hold the JWT. Shared infrastructure owns those concerns.

## Availability and GPS

1. Obtain Android location permission in the UI/platform layer.
2. Call `updateWaitingLocation(GeoPoint(...))` before `setOnline(true)`.
3. While online without an active order, refresh waiting location every 30–60
   seconds. Stop when offline, signed out, or location is unavailable.
4. During an assigned order call `updateOrderLocation(...)` at the foreground
   interval selected by the UI team. The backend emits the private order-room
   event used to move the customer's provider marker.
5. Never fake movement. Show stale/offline state and an explicit retry when
   permission, GPS or network is unavailable.

The backend rejects online activation when the account is not approved/active
or its location is stale. Display the safe API error; do not bypass it.

## Offers

`ProviderWorkState.pendingOffers` comes from
`GET /providers/me/offers/pending`. `offer.created` and `offer.expired` trigger
a REST reload, so reconnect and missed socket events remain safe.

Show incident, estimated decimal price/weather breakdown, customer location,
the server `expiresAt` countdown, and accept/reject controls. Disable controls
while `state.isBusy`. Accept/reject are never automatically retried because a
replay can mutate business state twice. After an ambiguous network failure,
refresh offers and orders before enabling another action.

## Active-service state machine

Render actions from server `OrderStatus`; never invent local transitions.

| Server status | Provider action |
| --- | --- |
| `ACCEPTED` | Navigate to the customer and mark arrived. |
| `ARRIVED` | Ask for the short-lived service-start token, then start. |
| `IN_PROGRESS` | Perform service and propose the final price. |
| `AWAITING_PRICE_APPROVAL` | Wait for customer decision. |
| `PRICE_DISPUTED` | Wait for Admin resolution. |
| `AWAITING_PAYMENT` | Wait for the sandbox adjustment. |
| `PAID` | Complete service. |
| `COMPLETED` | Read wallet credit and optionally review. |

The start token is not a payment QR, expires after five minutes, and must not be
logged or persisted. Final prices and withdrawals use canonical decimal strings
such as `125000.00`; never convert money through `double`.

After a rejected final-price proposal, Provider can submit another proposal or
call `disputeFinalPrice(reason)`. Completion stays blocked until final price and
payment adjustment are settled by the backend.

## Wallet and withdrawal sandbox

`ProviderWalletState` exposes total, locked and available balances, latest
ledger entries, and withdrawal history. Transaction amounts are always
positive; derive `+`/`-` from `WalletTransactionType`.

Only `availableBalance` can be requested. Backend atomically reserves funds,
allows one pending request and requires Admin resolution. Screens must visibly
say **Sandbox / demo only**. Current builds never make real payouts.

## Realtime and recovery

- Provider socket joins `provider:{providerId}` for offers.
- Selecting an order follows `order:{orderId}` for status, GPS and chat.
- Logout disconnects socket and listeners.
- Reconnect causes REST resync for pending offers and selected order.
- Connection status is not proof that cached business state is current.

## UI integration checklist

- Render `AsyncValue` states plus `state.lastFailure`.
- Disable duplicate actions while `state.isBusy`.
- Use server timestamps for offer expiry and GPS freshness.
- Preserve chat image size/MIME restrictions.
- Never put JWT, webhook secret, DB credentials or SePay secret in Dart,
  assets, screenshots or logs.
- Keep a no-map-key fallback showing coordinates/status for the free demo.
