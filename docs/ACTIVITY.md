# Activity module

`ActivityScreen` uses the shared light theme with white cards, black text,
black actions and neutral status badges. `HoatDongScreen` remains a compatibility
entry point for `/hoat-dong`. Horizontal chips filter all, SOS, maintenance and
charging records; orders sort newest first and are grouped by local month/year.
The list shows date, status, service, provider, location and derived price.
Cancelled cards say no payment; active cards label estimated costs and disable
rebooking. Detail and rebook actions retain the selected order ID.
The “Hoạt động” title is centered, and the list omits the sample/session caption.

`ActivityTextStyles` derives its Montserrat font family, line heights and letter
spacing from Home's `AppTextStyles` in `app_theme.dart`. The centered header is
18pt bold; service titles are 16pt bold. Filter labels are 13pt with white
semibold text on the selected black chip and medium black text on unselected
chips. Month headings use 14pt semibold muted text with 12px top/8px bottom
padding. Cards use 12pt metadata and status labels, 13.5pt mechanic/action text,
12.5pt two-line addresses and 13pt bold payment/price text. Existing icons, order
data, status colors, card structure, filters and navigation remain unchanged.

Active orders open the new [rescue progress details](ORDER_DETAILS.md) screen
with horizontal progress, timeline and map/contact actions. The existing invoice
retains its cost breakdown, rating, complaints and rebooking actions.

- `/hoat-dong` displays active orders and history.
- `/order-details?id=<order-id>` resolves rescue progress from shared state.
  Active Activity cards and the tracking header open this screen.
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
complaints remain in memory for the app session and reset on restart. Invoice
pages label sample data; complaints do not claim delivery to customer support.
Rebooking uses a dialog matching its invoking screen, confirms the vehicle and
address, creates a new pending order, and
clears the previous provider, parts, discount, ETA and rating. One new rescue
request is allowed at a time. Prices for rebooking are sample estimates.

Cancellation uses a shared blue `#1976D2` reason dialog across progress,
invoice and tracking screens. Five single-choice options accompany an optional
note; choosing “Lý do khác...” requires nonblank details, while typing a reason
without choosing an option is also accepted. Whitespace alone cannot enable
confirmation. “Tiếp tục cứu hộ”, dismissing the overlay and Back leave the order
unchanged. Confirmation records the reason, moves an active order into history,
shows “Đã hủy đơn thành công” and returns to `/trang-chu`. If the order became
terminal while the dialog was open, confirmation reports the unavailable action
and stays on the invoking route.

`OrderCancellationReason` validates and trims drafts outside Widgets. Its JSON
contains a stable `code`, Vietnamese `label` and trimmed `details`, ready for a
future cancellation API adapter. `RescueOrder.cancellationReason` retains it
alongside a timestamped cancellation event; `copyWith` and JSON preserve both.
Legacy order records without reasons remain readable. Reasons are session data,
with no new backend submission or disk persistence. Internal callers of
`cancelOrder` may omit a reason for compatibility; the shared UI always supplies
a validated reason.

Invoices for incomplete or cancelled orders label their amounts as estimates.
Ratings can only be saved for completed orders. Complaints require at least ten
characters after trimming surrounding whitespace and retain the selected order ID.

Completed invoices also open `/service-rating?id=<order-id>` through “Đánh giá
chi tiết”. The [rating screen](SERVICE_RATING.md) adds multiple quick tags,
optional comments/photos and a return to Home. Detailed reviews remain in
`serviceRatingsProvider` for the session and update the shared Activity star
rating only after a successful submission. Existing inline quick rating remains
available.

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

[Activity typography preview](screenshots/activity-typography.png) and
[320px with 1.5x text](screenshots/activity-typography-large-text.png).
[Cancellation reason dialog preview](screenshots/cancel-order-reasons.png).
