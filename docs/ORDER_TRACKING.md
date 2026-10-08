# Rescue order tracking

`OrderTrackingScreen` lives in
`lib/features/rescue/screens/order_tracking_screen.dart`. Checkout replaces its
route with `/order-tracking?id=<saved order ID>` immediately after placing an
order. The screen reads the same Activity order, preserving its selected shop,
packages, quantities, voucher-adjusted total, incident address and coordinates.
Active invoices also provide a “Theo dõi lộ trình thợ” action. Invalid IDs show a
recoverable empty state. The older `/rescue-tracking` radar route remains available
to existing callers.

The full-screen scaffold and draggable status card use white surfaces,
`#111827` text and `#CC0001` route, badges, contact controls and totals. The card
shows the current tracking heading, estimated time/distance, a mechanic avatar,
name, shop, rating, plate/model, contacts, selected services and the actual total.
Its content scrolls on small displays and with large text; the map stays above
the sheet, including native map attribution.

## Map and simulation

`OrderTrackingJourney` creates a simulated coordinate path from the chosen shop
to the order's incident coordinate. When a shop is unavailable, a short sample
approach is generated relative to the actual incident point. Coordinates are
never invented for an address-only order; that order retains its address and
shows “Đang chuẩn bị lộ trình”.

`OrderTrackingMap` uses the existing Google Maps configuration from
[LOCATION.md](LOCATION.md). It renders a red SOS bitmap at the customer's fixed
coordinate, a red motorcycle bitmap at the mechanic's moving coordinate, and a
red polyline for the remaining path. The camera initially fits the full route;
the route button restores that view after a pan or zoom. Without a supported
native SDK/key, `SimulatedTrackingMap` displays a clearly labeled grid diagram
with the same route and markers. It does not claim to be Google map tiles.

A `Timer.periodic` advances the path every 1,500 ms. An `AnimationController`
interpolates between checkpoints for smooth marker movement. Remaining distance
and a five-minute sample arrival estimate decrease as the marker approaches SOS.
At the endpoint, motion stops and the card shows “Thợ đã đến vị trí của bạn”.
Reduced-motion settings, backgrounding the app, opening chat and pushing a
full-screen route pause the simulation. The timer/controller are disposed with
the screen. Cancelling stops
motion, and repairing/completed/cancelled orders retain their stored status.

All movement and route estimates are explicitly labeled **mô phỏng**. The path
is not a Directions response, and the moving marker is not a mechanic's GPS
stream. The timer never changes the shared order into an accepted, repairing or
completed order. Closing and reopening the route starts its demonstration again.
Real dispatch, road routing and live tracking require a backend/feed.

## Contacts and cancellation

The mechanic card uses assigned provider information when present and otherwise
the requested sample name/plate/model. The avatar, rating and vehicle model are
sample presentation data. “Gọi điện” delegates to the shared Activity URL
launcher only when the order has a provider phone number. Missing numbers and
launcher failures provide feedback; a phone number is never fabricated for the
sample mechanic.

“Nhắn tin” opens a keyboard-aware conversation sheet. Entered messages remain in
the current tracking screen when that sheet is closed and reopened. The sheet
explicitly labels messages as local simulation; it sends nothing to a mechanic
and generates no fake replies. Its close button remains visible while messages
scroll. Leaving the tracking screen clears this local conversation.

“Hủy đơn hàng” uses `ActivityActions.cancel`, including confirmation and the
shared Activity state. Dismissing confirmation retains the order. A confirmed
cancellation updates all screens and disables contact controls. The invoice
action continues to expose full price/order details.

## Review and validation

Review captures: [tracking](screenshots/order-tracking.png) and
[chat simulation](screenshots/order-tracking-chat.png). These use the explicit
diagram fallback and sample order data, without a Google Maps key.

`test/order_tracking_screen_test.dart` checks exact incident coordinates,
decreasing route distance, marker/polyline data, interpolated movement and
arrival, reduced motion, backgrounding, disposal, cancellation, phone handling,
local chat retention, missing coordinates/IDs, completed orders, reopening from
an invoice and 320px / 1.5x text / keyboard layouts. Existing marketplace and Home
tests verify direct Checkout navigation, retained booking values and duplicate
order blocking. Live Google tiles and physical-device behavior need the SDK keys
and device validation described in LOCATION.md.

The completed implementation passed 220 tests, `flutter analyze --no-pub` and
the repository's Dart formatting check. `flutter build apk --debug --no-pub`
successfully produced `build/app/outputs/flutter-apk/app-debug.apk`.

Map API references: [GoogleMap](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/GoogleMap-class.html),
[bitmap markers](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/BitmapDescriptor/bytes.html),
and [Polyline](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/Polyline-class.html).
