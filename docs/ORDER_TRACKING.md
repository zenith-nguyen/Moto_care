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
bottom card has 28px top corners and initially leaves the upper half available
for the map. The header pairs a pastel service icon with the actual order code,
service name and a circular Copy action. A pale 16px overview has three equal
columns: incident address, the existing requester name and a blue status pill.
The 16px mechanic card retains the name, plate, image/initials and both Chat/Call
actions, with a pastel orange initials avatar and navy Call control.
The sheet retains Google Fonts Montserrat with -0.3 letter spacing, a light
slate background, white surfaces and a slate drag handle.
Below the contact card, the vertical route history reads the existing
`orderDetailsProvider` timeline without creating status events or timestamps.
Orange/teal dots connect each unchanged description and address to its recorded
time/date; missing times keep their existing placeholder. “Xem tất cả” opens
the same order-details route. Copy writes the stored code to the clipboard.
Connection/demo notices remain next to the mechanic card. The existing
service/distance/ETA metrics, explanation,
shop, selected services, price, full address and cancellation action remain
available by scrolling. No bottom-navigation widgets or shared state changed.
Small displays and large text wrap the status
and move contact controls onto a separate row.

The SOS pin stays at the incident coordinates. The motorcycle bitmap,
remaining polyline (width 5) use teal `#14B8A6`, with round line joins/caps and
soft circular marker halos. Matching pre-rendered teal bitmaps keep both pins
visible before the detailed icons load. Coordinates, road points, metrics,
status labels and contact/cancellation handlers are unchanged.

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

No backend endpoint or feed protocol was supplied for this task. The default
provider therefore remains null and retains the clearly labeled demo flow.
To enable real tracking, supply a production `OrderTrackingFeed` adapter and
configure the existing Google Maps keys.

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

Review captures: [overview](screenshots/tracking-redesign-overview.png),
[history](screenshots/tracking-redesign-history.png) and
[320px with 1.5x text](screenshots/tracking-redesign-large-text.png). They use
Montserrat and an injected example feed with the explicit diagram fallback.

`test/order_tracking_screen_test.dart` covers full-screen map geometry, exact
incident coordinates, teal width-5 polylines and halo marker bitmaps, live GPS/route
and ETA updates, empty-route bounds, immutable observations, stale/other-order
filtering, connection loss/recovery, subscription cleanup, arrival, demo
interpolation and lifecycle, cancellation, phone/chat navigation, local chat
retention, missing IDs/coordinates and small-screen keyboard layouts.
Marketplace tests retain checkout navigation and actual booking values.
Run formatting, `flutter analyze`, `flutter test` and
`flutter build apk --debug`. Native tiles and physical-device behavior require
the SDK keys and device validation described in LOCATION.md.

API references: [GoogleMap](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/GoogleMap-class.html),
[animateCamera](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/GoogleMapController/animateCamera.html),
and [Polyline](https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/Polyline-class.html).
