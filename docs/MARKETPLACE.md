# Rescue marketplace

The booking flow uses white / `#F8F9FA` surfaces, `#111827` main text,
`#4B5563` secondary text and `#CC0001` primary actions, prices and service icons.
All eight Home service tiles open `/partners?service=<service title>`.

## Navigation and cart

- `PartnerListScreen` searches open shops by name/address, filters vehicle
  capabilities and sorts by distance. Cards show verification, rating, supported
  vehicles, estimated arrival time and the lowest price for the requested service.
- `/partners/:partnerId?service=<title>` opens `PartnerDetailScreen`. Each menu
  comes from `MarketplaceCatalog`; quantities range from zero to nine. Continuing
  requires at least one selected package and an open shop. The cart is passed as
  an immutable `MarketplaceBooking` to `/checkout`.
- `CheckoutScreen` validates the cart against the current shop/menu before saving.
  It displays package quantities, a shared garage vehicle, incident address and
  notes, payment preference, vouchers, service subtotal and travel fee. The travel
  estimate is 10,000 VND plus 5,000 VND per rounded-up kilometer. Distances use
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

Payment defaults to cash. MoMo and MotoCare Wallet currently record a preference;
there is no wallet integration, charge or mechanic dispatch. Checkout and tracking
explicitly label the session demo. Partner identities, capabilities, verification,
menu prices and arrival estimates remain sample data supplied through
`partnerShopsProvider`; an API can replace this boundary.

SOS20 and MOTO20 discount 20,000 VND on service subtotals of at least 50,000 VND.
DEM15 discounts 15% only when all packages are night rescue. Expired/used offers
and unsupported codes provide no discount. Voucher eligibility is checked again
at submission, and a voucher is marked used only after an order is saved.

## Orders and tracking

`ActivityController.createOrder` retains the partner ID/name, immutable package
items, payment method, voucher, notes, GPS coordinates and the exact displayed
subtotal/travel/discount. `basePrice` continues to include the travel fee for
compatibility with existing invoice calculations. Old JSON defaults to an empty
item list, cash payment and no partner/voucher. New records retain all fields
when serialized or updated. Only one active order can exist.

Checkout now opens `/order-tracking?id=<order ID>` directly. It shows the
white/black/red mechanic card, two map markers and an explicitly simulated route
whose motorcycle moves every 1.5 seconds. The simulation never changes the shared
order into a fabricated acceptance. Customers can inspect the invoice, call an
assigned phone, use local demo chat or cancel through shared Activity actions.
See [ORDER_TRACKING.md](ORDER_TRACKING.md) for camera, lifecycle and map-key behavior.
The older `/rescue-tracking` radar route remains available for existing callers.

## Validation

`test/marketplace_flow_test.dart` covers cart quantities, prices, vouchers,
payment, JSON, cancellation, missing routes, GPS/manual-entry races and 320px
layouts with 1.5x text and the keyboard. `test/device_location_service_test.dart`
checks native permission handling and bounded coordinate acquisition. Home tests
exercise all eight service entry points, duplicate blocking and garage/GPS
retention. Physical-device GPS/geocoding and wallet/backend integration require
separate device/service validation.

Rendered previews: [partner list](screenshots/marketplace-partners.png),
[service menu](screenshots/marketplace-detail.png),
[checkout](screenshots/marketplace-checkout.png),
[payment and prices](screenshots/marketplace-payment.png), and
[order tracking](screenshots/order-tracking.png).
