# Station details

Home station cards and directory/list/map cards open
`/stations/:stationId?service=<selected category>`, passing a typed
`StationModel`. `StationDetailScreen` uses a scoped white/black theme with
`#E53935` actions and the existing Montserrat font. A swipeable
`CarouselSlider` displays the station's local photos; the white 24px profile
card overlaps the bottom of the banner. Back, native Share and session Bookmark
controls sit above the photo. The footer keeps booking and chat visible.

`StationModel` combines the existing station identity, Home image/review/response
metadata, profile data and the existing marketplace menu. Providers derive GPS
distance through the same boundary as Home, retain favorites by ID and filter
confirmed reviews using the order's partner ID. Screens and widgets contain no
sample station records, prices or mechanic counts. Profiles are injectable
through `stationProfilesProvider`; the directory remains sample data.

The supplied assets currently provide one photo per station, so each default
gallery shows `1/1`. Additional photos of the same station can be supplied in
`StationProfile.imageAssets`; the carousel counter then follows swipes. Empty or
failed images show a storefront placeholder. Photos from another station are
never added to fabricate a gallery.

The primary service list uses the same packages/prices as booking: tubeless tire
repair, battery jump and towing where supported. Displayed prices therefore
match the cart; battery jump remains 40,000 VND from the existing catalog.
The sample Revo profile supplies 12 mechanics and a warranty label; unconfigured
profiles use contact placeholders instead of invented counts/commitments.

`StationServicesSection` retains the introduction and delegates the read-only
price list to `StationServicesCatalog(List<ServiceCatalogModel>)`. Each white
16px rounded card shows a red vector icon, fulfillment badge, equipment/time
description, locale-formatted price and a chevron. Tapping a card opens the
scrollable `ServiceCatalogDetailsSheet`, with procedure steps, material
commitments and warranty information. It never selects a package, changes cart
quantities or creates an order; the existing sticky booking action remains the
entry point for requesting service.

`StationDetailsService` joins `StationProfile.serviceDetails` to supported
packages by ID while retaining their marketplace names and prices. The sample
Revo profile supplies the three service descriptions and a 30-day patch warranty.
Other stations show contact guidance when details are unpublished. Profile maps,
procedure lists and the derived catalog are immutable copies. Catalog amounts
are service prices; the sheet explains that any travel fee is displayed before
confirmation, preserving the existing checkout calculation.

Booking opens the existing partner packages with the selected station ID and
Home service category preserved. Closed stations or unavailable menus disable
booking. Opening the detail page, sharing, bookmarking, chat or reviews creates
no rescue order. Chat opens the existing `ChatDetailScreen` with that station's
name, phone and opening label, without inventing an assigned mechanic or plate.
Chat retains its existing local simulation boundary.

The rating spec opens `/stations/:stationId/reviews` /
`MechanicReviewsScreen`. Aggregate rating/count values come from Home metadata;
available detailed reviews come from confirmed session ratings for that station.
There is a recoverable empty state when no written reviews are available. No
remote review download, persistent favorites or backend upload is added.

Deep links resolve the current directory without requiring a route extra.
Unknown/removed station IDs show a message and Home action. The native Share
adapter is injectable; it sends the station information and its Google Maps
coordinates, with the share button's rectangle as the popover origin. Share
failure allows retry and keeps the current station/favorite state.

Specs display four columns normally and two columns on narrow/large-text
layouts. Address, name, description, prices and the sticky CTA wrap as needed.

Rendered previews with the bundled Montserrat and supplied station photos:
[profile](screenshots/station-detail.png),
[services and sticky actions](screenshots/station-detail-services.png), and
[320px / 1.5x text](screenshots/station-detail-large-text.png).

Updated catalog previews:
[reference prices](screenshots/station-services-catalog.png),
[service procedure](screenshots/station-service-procedure.png), and
[catalog at 320px / 1.5x text](screenshots/station-catalog-large-text.png).

Run Dart formatting, `flutter analyze`, `flutter test` and a debug Android build.
The station tests cover data and service-price consistency, typed Home/directory
navigation, category-preserving booking, closed/missing stations, favorites,
reviews, station-specific chat/share, carousel swipes and 320px large text.
Catalog tests also cover service-specific sheets, unchanged cart/order state,
preserved scroll position, unpublished metadata and the empty state.
