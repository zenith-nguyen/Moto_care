# Rescue marketplace

The partner browsing flow uses white / `#F8F9FA` surfaces, `#111827` main text,
`#4B5563` secondary text and `#000000` primary actions, prices and service icons.
The order summary scopes its primary action, total and incident pin to
`#E53935` through `OrderSummaryTheme`.
All eight Home service tiles open `/partners?service=<service title>`.

## Navigation and cart

- `PartnerListScreen` searches open shops by name/address, filters vehicle
  capabilities and sorts by distance. Cards show verification, rating, supported
  vehicles, estimated arrival time and the lowest price for the requested service.
- `/partners/:partnerId?service=<title>` opens `PartnerDetailScreen`. Each menu
  comes from `MarketplaceCatalog`; quantities range from zero to nine. Continuing
  requires at least one selected package and an open shop. The cart is passed as
  an immutable `MarketplaceBooking` to `/checkout`.
- `CheckoutScreen` remains the compatibility entry point for `/checkout` and
  renders `OrderSummaryScreen`. The controller validates the cart against the
  current shop/menu before saving. The summary displays a circular station photo,
  distance badge, editable incident address/GPS, service quantities, a shared
  garage vehicle, notes and payment preference. A sticky red confirmation button
  opens the live tracking route after creating the order.
  The travel estimate is 10,000 VND plus 5,000 VND per nearest whole kilometer
  (half kilometers round up): 1.2 km costs 15,000 VND, and a 30,000 VND service
  therefore totals 45,000 VND. Distances use
  straight-line GPS distance when available, otherwise sample reference distances.
- An invalid/missing checkout extra, missing shop or missing tracking order gets
  a recoverable empty state. Returning from checkout preserves the detail cart;
  browsing or dismissing screens creates no order.

## Location and payment

`deviceLocationProvider` is an injectable foreground location boundary using
`geolocator` and `geocoding`. Checkout keeps an already confirmed incident
location. With no location, it requests device GPS and resolves an address where
supported. If reverse geocoding fails, it displays the actual coordinates.
Denied permissions, disabled GPS and timeouts allow manual address entry and
retry. Typed addresses discard old coordinates; late GPS responses never
replace a user's newly typed address. Android declares coarse/fine location;
iOS and macOS declare foreground usage descriptions and macOS location entitlements.
Incident search and map screens now use configurable Places/Geocoding APIs and
Google Maps, as described in [LOCATION.md](LOCATION.md).

Payment defaults to “Tiền mặt cho thợ”. The selection sheet offers cash, MoMo
and VNPay and records a preference; there is no wallet integration, charge or
mechanic dispatch. Historical MotoCare Wallet values remain readable in order
JSON. Checkout removes implementation/demo text from the station and price cards;
tracking retains its explicit simulation label.
Partner identities, capabilities, verification,
menu prices and arrival estimates remain sample data supplied through
`partnerShopsProvider`; an API can replace this boundary.

Checkout has no promo-code entry or voucher selection. The breakdown displays
“Giảm giá (Voucher)” as `-0đ`. The quoted total is the service subtotal plus the
travel fee, and new orders have zero discount. Display and submission use the
same provider quote; submission rejects a stale displayed travel fee.

## Orders and tracking

`ActivityController.createOrder` retains the partner ID/name, immutable package
items, payment method, notes, GPS coordinates and the exact displayed
subtotal and travel fee. `basePrice` continues to include the travel fee for
compatibility with existing invoice calculations. Old JSON defaults to an empty
item list, cash payment and no partner. Historical discount and voucher fields
remain compatible with existing JSON; nonzero historical adjustments still
contribute to invoice totals. New records retain all fields
when serialized or updated. Only one active order can exist.

Checkout now opens `/order-tracking?id=<order ID>` directly. It shows the
white/black mechanic card, two map markers and an explicitly simulated route
whose motorcycle moves every 1.5 seconds. The simulation never changes the shared
order into a fabricated acceptance. Customers can inspect the invoice, call an
assigned phone, use local demo chat or cancel through shared Activity actions.
See [ORDER_TRACKING.md](ORDER_TRACKING.md) for camera, lifecycle and map-key behavior.
The older `/rescue-tracking` radar route remains available for existing callers.
Its details action and Checkout's “Xem đơn đang diễn ra” open the
[rescue progress screen](ORDER_DETAILS.md) with the selected order ID. Returning
from progress restores the same checkout cart and keeps new ordering disabled
while that order is active.

## Validation

`test/marketplace_flow_test.dart` covers cart quantities, full prices without vouchers,
payment, JSON, cancellation, missing routes, GPS/manual-entry races and 320px
layouts with 1.5x text and the keyboard. `test/device_location_service_test.dart`
checks native permission handling and bounded coordinate acquisition. Home tests
exercise all eight service entry points, duplicate blocking and garage/GPS
retention. Physical-device GPS/geocoding and wallet/backend integration require
separate device/service validation.

`test/order_summary_screen_test.dart` checks the 45,000 VND example,
kilometer rounding boundaries, red confirmation/total, address editing,
GPS/notes/VNPay retention through tracking, duplicate confirmation and payment
sheet dismissal.

Order summary validation: formatting and analysis passed, all 302 tests passed,
and the Android debug APK built successfully with an isolated Gradle daemon.
Checks used a temporary project copy with matching changed Dart sources.

Updated summary previews: [order summary](screenshots/order-summary.png),
[payment and notes](screenshots/order-summary-payment.png), and
[large text](screenshots/order-summary-large-text.png).

Rendered previews: [partner list](screenshots/marketplace-partners.png),
[service menu](screenshots/marketplace-detail.png),
[checkout](screenshots/marketplace-checkout.png),
[payment and prices](screenshots/marketplace-payment.png), and
[order tracking](screenshots/order-tracking.png).
