# Rescue order live tracking

`OrderTrackingScreen` lives in
`lib/features/rescue/screens/order_tracking_screen.dart`. Checkout opens
`/order-tracking?id=<saved order ID>`; active invoices can reopen the same route.
The screen reads the shared Activity order, retaining its code, selected shop,
packages, quantities, total, incident address and coordinates. Invalid IDs show
a recoverable empty state. The older `/rescue-tracking` route remains available.

## Layout and map

A full-screen Stack places Google Map beneath a floating, centered “Theo dõi
trực tiếp” header with circular Back and order-details buttons. The white draggable
bottom card has 24px top corners. Its first three rows show the actual order code
and status pill; service, remaining distance and ETA; and the mechanic avatar,
name, plate and circular Chat/Call controls. Dragging up reveals the tracking
explanation, shop, selected services, price, address and cancellation action.
Typography remains Montserrat. Small displays and large text wrap the status
and move contact controls onto a separate row.

The SOS pin stays at the incident coordinates. The motorcycle bitmap,
remaining polyline (width 5) and contact icons use `#E53935`; the status pill uses
an orange tint. A pre-rendered red motorcycle bitmap keeps the marker visible
before the detailed icon loads. No other screen's accent colors change.

`OrderTrackingMapData` accepts route points from the service and reserves camera
padding for the header and current card height without resizing the map.
`animateCamera` fits both customer and mechanic plus route points, even if the
route is empty or omits its endpoints. Live position/route updates and sheet
changes refresh the camera; the route button restores the view after a pan.
When only the incident location is known, just its SOS marker is shown.

Google Map uses the existing native configuration in [LOCATION.md](LOCATION.md).
Without a supported SDK/key, the fallback renders a clearly labeled location
diagram with the same positions and route; it does not display Google tiles.

## Backend integration

The UI widgets consume a `TrackingSnapshot` prepared by
`OrderTrackingService`. The `OrderTrackingFeed` interface is the transport
boundary: `Stream<TrackingUpdate> watchOrder(String orderId)`. Adapt the actual
repository, WebSocket or SSE stream outside widgets and inject it at the app's
ProviderScope:

```dart
orderTrackingFeedProvider.overrideWithValue(yourBackendTrackingFeed)
```

Each immutable `TrackingUpdate` provides the order ID, observation time, mechanic
LatLng and a list of road-route LatLng points ordered toward the incident. It
can also provide distance in kilometers, ETA in minutes, arrival, customer
coordinates and mechanic contact/avatar details. Widget code contains no sample
order ID, name, plate, distance or ETA. The stored incident coordinate takes
precedence over a feed coordinate; a feed can supply it for an address-only
order. Backend route points are drawn exactly as received.

The StreamProvider subscribes only for a valid, active order. The controller
rejects other-order and older observations, retains the last accepted position
on stream errors, displays a connection notice and clears it on recovery.
Cancelling/completing an order or leaving the tracking route cancels the
subscription. The adapter owns reconnection and transport cleanup; a broadcast
transport shared elsewhere should remain open while other listeners use it.
Authoritative order status stays in Activity; GPS events do not accept or
complete an order.

A configured feed disables the demo timer, including while the first GPS event
is pending or the connection fails. Reduced-motion settings pause animation
without suppressing actual backend GPS updates. Unknown distance/ETA display
“—”; when distance is omitted, the service can sum the supplied route segments.
ETA is never estimated from demo data in live mode.

The live application uses the authenticated order/realtime adapters already
registered in the app foundation. `provider.location_updated` moves the
mechanic marker and REST order snapshots repair missed events after reconnect.
When no Google key is configured, live sessions render the customer, mechanic
and route on OpenStreetMap. Google Maps remains an optional adapter. Widget
tests deliberately keep the isolated schematic/demo feed unless they override
the live integration providers.

## Demo and contacts

With no configured feed, `OrderTrackingJourney` creates a demonstration path
from the selected shop, or a nearby sample origin, to the exact incident point.
A 1,500ms timer and Flutter animation interpolate the mechanic and reduce the
sample distance/five-minute ETA. Arrival stops motion. Reduced motion,
backgrounding, chat and full-screen route transitions pause the demo. Its
timer/controller are disposed with the screen. Address-only orders never
receive fabricated coordinates. The card explicitly labels this flow
“Lộ trình mô phỏng”.

Assigned/live mechanics open the existing `/chat-detail` screen with their
name, plate, phone and order context. An unassigned demo mechanic opens the
existing local conversation sheet; its messages remain when closed/reopened
within the tracking route and are labeled as unsent simulation. Neither path
adds a backend messaging transport. Call uses the existing injectable phone
launcher and only a supplied phone number; missing numbers and launcher errors
provide feedback.

“Hủy đơn hàng” opens the shared [blue cancellation reason dialog](ACTIVITY.md).
Keeping the order resumes tracking; confirmation saves the reason in shared
Activity state, stops movement, closes the GPS subscription and returns to Home
with a success SnackBar. The details
button opens `/order-details?id=<order-id>` for rescue progress and the status
timeline; its invoice link retains full costs and rating actions.

## Review and validation

Review captures: [Live tracking](screenshots/live-tracking.png) and
[320px with 1.5x text](screenshots/live-tracking-large-text.png). They use
Montserrat and an injected example feed with the explicit diagram fallback.

`test/order_tracking_screen_test.dart` covers full-screen map geometry, exact
incident coordinates, red width-5 polylines and marker bitmaps, live GPS/route
and ETA updates, empty-route bounds, immutable observations, stale/other-order
filtering, connection loss/recovery, subscription cleanup, arrival, demo
interpolation and lifecycle, cancellation, phone/chat navigation, local chat
retention, missing IDs/coordinates and small-screen keyboard layouts.
Marketplace tests retain checkout navigation and actual booking values.
Run formatting, `flutter analyze`, `flutter test` and
`flutter build apk --debug`. Physical-device GPS/realtime still requires device
validation; Google-native tiles require its SDK key, while the no-key build uses
OpenStreetMap under the usage rules described in LOCATION.md.

API references: [GoogleMap](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/GoogleMap-class.html),
[animateCamera](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/GoogleMapController/animateCamera.html),
and [Polyline](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/Polyline-class.html).
