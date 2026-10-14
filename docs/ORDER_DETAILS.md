# Rescue order progress details

`OrderDetailsScreen` at `/order-details?id=<order-id>` renders the selected shared
Activity order. Active orders open it from Activity's “Chi tiết đơn” action;
tracking's details action and the invoice's “Xem tiến trình cứu hộ” link use the
same order ID. Checkout's “Xem đơn đang diễn ra” and the legacy rescue radar's
“Xem chi tiết đơn” also open this screen instead of the older invoice progress
layout. Back restores the invoking route and its checkout draft, or returns to
Activity for a direct link.
Missing/unknown IDs show an empty state instead of selecting a sample order.

The screen uses Montserrat with a scoped white/black/red `#E53935` theme. Small
widgets render the order code/status, four connected horizontal progress steps,
rescue information, mechanic contact and vertical status timeline. Narrow
screens and enlarged text stack the order badge, detail values and contact
actions; the whole body scrolls without hiding content.

The red map action opens `OrderTrackingScreen` for the same ID and disables for
terminal orders. Chat preserves the assigned mechanic and order context through
the existing conversation route. Call delegates a `tel:` URI to the existing
injectable `url_launcher` boundary; unavailable contacts disable their actions,
and launcher failures show the actual phone number. Copy writes the actual code
to the system clipboard. Invoice, rating, complaints and rebooking remain
available through the existing invoice route. Cancellation opens the shared
[blue reason selector](ACTIVITY.md), saves the chosen reason and optional note,
then shows a success SnackBar and returns to Home. Keeping the order or dismissing
the dialog leaves the progress and tracking state unchanged. The dialog scrolls
with enlarged text and keyboard insets, and its blue controls override this
screen's red theme.

`orderDetailsProvider` watches Activity and profile data. `OrderDetailsService`
derives immutable display steps and timeline entries. The four step positions
are received, en route, repairing and completed, distinct from the older invoice
Stepper's index convention. Cancellation does not mark the order completed.

`RescueOrder` now accepts `requesterName`, `requesterPhone` and an immutable
`statusEvents` list; JSON conversion and `copyWith` preserve them. Each
`RescueOrderEvent` contains a typed status, `occurredAt` and optional description.
New session orders snapshot the confirmed profile and record their actual
creation time; cancellation appends a timestamp from the injectable order clock.
The optional typed `cancellationReason` and cancellation event description retain
the submitted reason; JSON and `copyWith` preserve it. Legacy records need no
cancellation metadata.
Older orders without requester snapshots use the current confirmed profile,
with clear placeholders for missing values.

Backend adapters can populate these fields when replacing initial order data or
updating shared Activity state. The service orders supplied events by time,
excludes events preceding creation or beyond the current active status, and
shows the current event first. The creation timestamp is the only assumed
milestone: missing transition timestamps display “—” rather than invented times.
Without a backend, the app does not simulate acceptance or completion.

Review captures: [normal](screenshots/order-details.png),
[timeline](screenshots/order-details-timeline.png) and
[large text](screenshots/order-details-large-text.png). Widget/service tests in
`test/order_details_screen_test.dart` cover navigation, copy/contact actions,
progress/timestamps, requester snapshots, JSON compatibility, cancellation,
missing data and narrow layouts.
