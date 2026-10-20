# Provider UI integration plan for PR #51

PR #51 is a valuable Provider UI source, but it is still a standalone demo
application. It must be adapted into the shared Moto Care application rather
than merged over the Customer runtime.

## Audit summary

The reviewed head (`7b00769`) changes 145 files and currently:

- replaces `lib/main.dart` with a Provider-only `MaterialApp`;
- replaces the shared `pubspec.yaml` and removes Riverpod, GoRouter, Dio,
  secure storage, Socket.IO, Firebase, maps and Customer dependencies;
- changes the Android application label from the shared app to `REVO Thợ`;
- stores orders, availability, chat, wallet and payouts in demo `AppState`;
- includes generated desktop plugin changes that must not be imported by hand.

The UI itself can be reused. Its runtime and package files cannot be used as
the integration boundary.

## Target layout

```text
lib/main.dart                         Customer runtime (preserved)
lib/main_provider.dart                Provider runtime entrypoint
lib/core/                             shared API/session/realtime/theme
lib/features/provider/                adapted Provider screens/controllers
lib/features/customer/ + other roles  existing Customer features
```

Both role entrypoints must use the existing `ProviderScope`, authenticated
session, repositories and router foundation. Server-confirmed role checks stay
authoritative.

Development commands after the Provider entrypoint lands:

```powershell
flutter run -t lib/main.dart `
  --dart-define=API_BASE_URL=https://your-origin.example

flutter run -t lib/main_provider.dart `
  --dart-define=API_BASE_URL=https://your-origin.example
```

## Shared visual language

`lib/core/theme/revo_brand.dart` is the canonical palette for both roles:

- primary `#317CBB`, deep primary `#246598`, sky `#70C5EB`;
- navy `#234560`, ink `#172638`;
- emergency/destructive red remains separate from normal blue actions;
- the canonical Customer `logo-revo.png` remains the source logo asset.

Provider widgets should import these tokens instead of keeping another
`AppColors` class. Customer primary buttons, links, selected navigation and the
logo use the same blue. SOS markers and destructive actions remain red for
clear meaning.

## Runtime migration order

1. Move Provider presentation files into `lib/features/provider/` without
   changing `lib/main.dart`, `pubspec.yaml`, router or generated registrants.
2. Replace demo availability with
   `providerLocationTrackingControllerProvider`.
3. Replace mock offers and active orders with `providerWorkControllerProvider`.
4. Reuse `customerChatControllerProvider(orderId)` for text and protected
   images; do not keep the simulated reply timers.
5. Replace demo wallet/payout state with `providerWalletControllerProvider` and
   retain the required Sandbox/demo wording until real payouts exist.
6. Add `lib/main_provider.dart`, role-aware routes and Android product flavor or
   a separate application ID only after both runtimes pass independently.
7. Run Customer and Provider tests plus both Android builds before merging.

## State mapping

| PR #51 demo state | Shared production boundary |
| --- | --- |
| `AppState.isOnline` | `providerLocationTrackingControllerProvider` |
| `AppState.activeOrder` / offers | `providerWorkControllerProvider` |
| simulated chat timers | `customerChatControllerProvider(orderId)` |
| `AppState.transactions` / withdrawals | `providerWalletControllerProvider` |
| local order transitions | backend `OrderStatus` snapshot + REST resync |

Never refresh stale Provider locations directly in the database. A Provider
must go online and upload a fresh GPS point before matching.

## Merge blockers

Do not merge the Provider prototype into a synchronized branch while any of
these are true:

- `lib/main.dart` no longer launches `MotoCareApp` inside `ProviderScope`;
- the shared dependencies disappear from `pubspec.yaml`;
- offers, movement, order status, payment or wallet claims are still mock data
  without an explicit demo label;
- Customer tests or the default Android build fail;
- Provider screens bypass shared authentication, API or Socket.IO clients.
