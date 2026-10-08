# Activity module

`ActivityScreen` uses the shared light theme with white cards, black text, orange
actions and red cancellation badges. `HoatDongScreen` remains a compatibility
entry point for `/hoat-dong`. Horizontal chips filter all, SOS, maintenance and
charging records; orders sort newest first and are grouped by local month/year.
The list shows date, status, service, provider, location and derived price.
Cancelled cards say no payment; active cards label estimated costs and disable
rebooking. Detail and rebook actions retain the selected order ID.

Active tracking, map/call/chat/cancel and the progress stepper now live in the
order-detail screen. The detail/invoice screen retains its existing theme.

- `/hoat-dong` displays active orders and history.
- `/chi-tiet-don-hang?id=<order-id>` resolves an invoice from shared state.
  Missing or unknown IDs show an empty state instead of another user's order.
- `RescueOrder` uses typed statuses with wire values `pending`, `en_route`,
  `repairing`, `completed`, and `cancelled`. Service labels are Vietnamese.
- Prices are integer VND. `basePrice = travelFee + laborFee` and
  `totalPrice = basePrice + extraPartPrice - discount`. The total is derived
  instead of storing a second amount that can disagree with the invoice.
- JSON conversion preserves these fields; unknown statuses/services are rejected.

`main.dart` provides a root Riverpod `ProviderScope`. `activityProvider` holds
immutable orders and complaints; both screens read the same state. Initial data
comes from `initialRescueOrdersProvider`, which tests can override.

The current implementation is a local demo. Orders, cancellations, ratings and
complaints remain in memory for the app session and reset on restart. The UI
labels its sample data and never claims a complaint was sent to customer support.
Rebooking uses a dialog matching its invoking screen, confirms the vehicle and
address, creates a new pending order, and
clears the previous provider, parts, discount, ETA and rating. One new rescue
request is allowed at a time. Prices for rebooking are sample estimates.

Cancellation requires confirmation and moves an active order into history.
Invoices for incomplete or cancelled orders label their amounts as estimates.
Ratings can only be saved for completed orders. Complaints require at least ten
characters after trimming surrounding whitespace and retain the selected order ID.

Map and phone actions use `url_launcher` with an encoded Google Maps search URL
and a `tel:` URI. Failures show the address or number. Chat opens the existing
`/chat-detail` route with the selected provider and order status. Bottom tabs
return to the existing Home page to preserve its account information.

For backend integration, replace the sample data and controller operations with
the project's Dio data layer. Real order submission, live provider tracking,
persisted history and delivery of complaints are not connected yet.

`test/activity_screen_test.dart` covers the retained detail actions and rebooking.
`test/be_screens_test.dart` covers category filters, month ordering, price/status
presentation and narrow layouts. `RescueServiceType` also accepts night rescue
and charging labels; there are no invented charging bookings in the initial data.
