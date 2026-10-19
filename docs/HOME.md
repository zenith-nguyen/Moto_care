# Home screen

`/trang-chu` keeps its existing `TrangChu` entry point and renders the Riverpod
`HomeScreen` in `lib/features/home/screens/home_screen.dart`. Revo Home uses a
scoped `RevoHomeTheme`: white (`#FFFFFF`), black (`#111111`, `#1C1C1E`) and light
gray (`#F5F5F7`), bundled Montserrat with Vietnamese support, and shared 16px
station-card corners. Blue marks station verification and the selected navigation tab. Authentication
retains its white/black `AuthTheme`; supporting screens keep `HomeTheme.light`.

## Station discovery

The supplied `assets/images/Thời tiết.png` sky/cloud image sits behind both
the header and weather card, including the status-bar area. A `DecoratedSliver`
wraps their shared `SliverMainAxisGroup`, so the backdrop scrolls with those
sections and sizes itself to their content, including larger text. The image's
white lower edge transitions into the station listing without a repeated image.
When the shared forecast reports `rainy` or `stormy`, Home switches that backdrop
to the supplied `assets/images/Trời mưa.png` and uses
`assets/images/Thời tiết mưa.png` for the weather icon. The icon's white
background has been removed, preserving a transparent PNG. Both changes follow
the same provider snapshot and revert when the forecast becomes dry. The blue
card, header layout, search and service controls keep their existing styling.
Loading/error states with no forecast use the original sky background.
The cutout was made with the built-in imagegen tool; the exact edit prompt is
saved in [the rain icon prompt](assets/home-rain-icon.prompt.txt).

`SmartWeatherRescueCard` replaces the Home video banner with a sky-blue
gradient (`#91C8EF` → `#80B3E6`), 24px corners, 16px padding and a soft shadow.
Its three layers contain a 36px bold white temperature and compact risk subtitle
on the left with only the shaded sun/cloud illustration on the right; a white
search field with 16px corners, 12px vertical margins and a pale-blue filter
control with 10px corners; and horizontally scrolling quick-service chips.
The selected chip uses dark blue (`#175D91`), white text and a checkmark;
other chips use a translucent blue fill without borders. Narrow screens and
larger text wrap the subtitle below the temperature in the same header row.
The stateful widget owns horizontal scrolling. Search and quick-service taps
forward booking callbacks; providers own the booking draft and weather request.
Rain artwork is enabled by the Home card's optional `rainAsset` argument to
`WeatherConditionIcon`; other consumers, including Admin, retain their existing
painted weather illustrations.

The header follows the reference's order: a blank circular account placeholder
on the left, “Vị trí của tôi” (12px, medium, black54) and the black location capsule in the middle, and the
notification bell on the right. The placeholder still opens Account and retains
the reactive account tooltip. The bell opens the Notifications tab of `/tin-nhan`.
The “Dịch vụ” action below the card opens the existing emergency-service sheet.

## Weather service boundary

`homeWeatherProvider` requests a `HomeWeather` through `HomeWeatherService`,
passing the confirmed `RescueLocation`. The default `MockHomeWeatherService`
returns the separate `demoHomeWeather` record (32°C, partly cloudy). The card
displays “32°” with “Nắng nóng • Dễ nổ lốp” below it; its accessibility label
identifies the demo as “Thời tiết mẫu” and keeps the Celsius unit.
`WeatherRescueService` derives the displayed alert:
rain/storm warnings take precedence over the demo heat threshold of 32°C.
These demo rules are presentation guidance, not measured roadside conditions.

An OpenWeatherMap adapter can replace `homeWeatherServiceProvider` using the
approved Dio client without changing the card. The adapter must use confirmed
coordinates, handle missing coordinates/network failures and supply real weather
values with `isDemo: false`; no API key or live request is included here.
Location changes refresh the auto-disposed provider, and Riverpod discards late
results from earlier requests. Loading and error states preserve search,
filters and quick services; a failed weather request has an explicit retry.

The “Bạn cần hỗ trợ gì? (Thủng lốp, hết bình...)” search control and
“Tất cả ⚡”, “🔋 Kích bình”, “🌊 Ngập nước”, “🚚 Xe kéo” and “🔧 Sửa tại chỗ”
chips open `EmergencyBookingBottomSheet` directly. Battery, flood and towing
chips preselect their incident type; “Tất cả”, search and “Sửa tại chỗ” start
with engine-failure assistance. The form keeps incident selection editable.
These actions preserve station filters and create no order until submission.
The adjacent filter button continues to open station discovery filters.

## Station listing

Horizontally scrolling categories precede a two-column station grid.
Cards show local shop photos, verification, sample response time,
rating/review count, station name and distance/area. The white floating navigation
bar keeps the labels “Trang chủ”, “Bản đồ trạm”, “Hoạt động” and “Tài khoản”.
On Home, the selected icon and label turn blue, with a pale blue background behind the
icon, across screens that use the shared bar.

Home and the station directory use the same `StationCardPhoto` crop, gradient,
badges and rating treatment. Shared typography in `app_theme.dart` supplies
16px bold station titles, 13px body text and 12px captions with consistent line
heights. Grid height grows with text scale; badges wrap instead of squeezing text.

`homeDiscoveryStationsProvider` combines the existing partner directory and
service capabilities with `homeStationDetailsProvider`. Immutable models and
`HomeDiscoveryService` keep filtering/sorting outside Widgets:

- Search accepts accented/unaccented Vietnamese station names, addresses and
  service labels, including “Vá xe”, “Vá lốp”, “Thủng lốp”, “Xe kéo” and “hết bình”.
- All stations sorts by distance; Fastest sorts by sample response time; Top
  rated sorts by rating. Open stations precede closed stations.
- Towing filters by towing capability. Tire repair 24/7 requires both tire repair
  capability and 24-hour opening.
- The filter sheet combines distance, 24-hour opening and verified status.
  Dismissing a draft changes nothing; Apply commits all options together.
- Zero results provide a reset action. Search/category/filter state survives
  switching main tabs and returning to Home.

Review counts and response times are explicit sample presentation metadata,
separate from completed rescue counts. They do not claim live dispatch estimates.
Station card image assignments and the legacy illustration assets are documented
in [HOME_ASSETS.md](HOME_ASSETS.md).

## Data and navigation

- The avatar and its account tooltip watch `profileProvider`. A `HomeUser` route payload seeds an
  uninitialized profile; an existing profile takes priority. Profile edits
  update the header without reopening the screen. Home does not display
  membership tiers, reward points, a Club card or offer cards.
- The “Dịch vụ” action opens an emergency-service sheet. Its vehicle row watches
  `defaultVehicleProvider`. The picker uses the
  garage's `vehicleProvider` and `setDefault`, so selection is shared with the
  vehicle screen. Dismissal leaves the default unchanged. Empty garages offer
  the existing add-vehicle route.
- `rescueLocationProvider` starts unset. `initialRescueLocationProvider` is the
  integration boundary for an address and optional GPS coordinates. Without a
  confirmed location, the header displays “Quận 1, TP.HCM” as a browsing area;
  this does not populate the rescue address/GPS state or enable checkout.
  Tapping the location label or capsule pushes `/incident-location` and opens
  `SelectLocationScreen` (“Vị trí gặp sự cố?”) first. Address selection, GPS or
  “Chọn trên bản đồ” continues to the existing `ConfirmLocationScreen` at
  `/incident-map-picker`. The rescue form's location action follows the same
  sequence and returns to that retained form, including its entered notes.
  Map confirmation saves shared location and returns through the search screen
  to the retained Home route or rescue form; it creates no order. Drafts do not update
  shared location until confirmation. Typed address changes clear
  stale coordinates. The map and current-location shortcut use configured native Maps, GPS and
  Places/geocoding services; see LOCATION.md for unavailable-key fallbacks.
- The shared light bottom bar contains four tabs: Home, Station map
  (`/tram-cuu-ho?view=map`), Activity and Account (`/tai-khoan`). Moving between
  secondary tabs replaces the current tab above Home, so returning preserves
  Home. Vehicles, Messages and supported menu destinations remain accessible
  from Account. Services remains a secondary route at `/dich-vu`.
- All eight service tiles open `PartnerListScreen` at `/partners`, passing the
  tile title as `serviceType`. The [marketplace flow](MARKETPLACE.md) then selects
  a shop and packages, checks out and tracks the saved order. Station cards
  open the [station detail screen](STATION_DETAILS.md) and then the selected partner's packages. Closed stations
  disable this booking action. The Towing/Tire categories pass their service
  selection to the packages screen. Emergency tips remain available from
  Services and Account.
- All eight service tiles remain available in the emergency-service sheet,
  with black icons. The weather card supplies Home search; the earlier standalone
  `HomeVideoHero` and its tests remain available but are not mounted on Home.

## Supporting request sheets and nearby stations

Home search and quick-service chips use `EmergencyBookingBottomSheet` (the
existing `CreateRescueRequestBottomSheet` name remains an alias). Service tiles
and station cards retain the [marketplace flow](MARKETPLACE.md).

The dynamic request sheet offers service-specific choice chips: tire repair at
30k/50k/90k, battery assistance at 40k/280k, fuel delivery at 45k/85k and flooded
engine repairs at 60k/120k. Both “Vá xe” and “Vá xe / Săm” select the tire options.
Other services offer an on-site inspection and rescue at 50k. Selecting a chip
updates the total immediately, with the first option selected initially.

The form retains the shared garage picker and adds vehicle categories (scooter,
underbone and manual/large-displacement bikes), an optional camera attachment
with preview/removal, and the incident description. It watches the current
address, optional coordinates and active orders. The black “TÌM THỢ CỨU HỘ NGAY”
button is disabled without vehicle/location or while an active request exists.
The location action can open the map above the sheet; returning retains the
same form, selections, photo and description.

Confirmation calls `ActivityController.createOrder` and retains the service,
vehicle, selected option/category, selected price, address, landmark and optional
coordinates in a pending `RescueOrder`. Camera bytes remain in memory for the
session and survive status changes, but are not serialized to JSON. The order
appears in Activity, the sheet closes, and Home pushes `/order-tracking?id=...`
for that order. Cancelling/dismissing the sheet creates nothing; an active
order prevents duplicate requests. Maintenance currently records a service
request; appointment slots and scheduling are not connected.

These requests are session-only prototypes. The confirmation explicitly states
that no mechanic is dispatched and no payment is charged. The dynamic sheet uses
the displayed option prices; other request flows retain the existing mock
pricing boundary. Actual costs need station confirmation.

Station cards consume `partnerShopsProvider`, backed by `rescueStationsProvider`.
With GPS coordinates they use straight-line distance; without coordinates they use the directory's reference
distances. The directory is still sample data and the UI labels it accordingly.
No live road distances or availability service is connected. The empty directory
has a dedicated message.

## Validation

Controlled 390 × 844 previews with bundled Montserrat and test session data:
[Home](screenshots/home-separated-navigation.png),
[emergency details](screenshots/home-emergency-booking.png), and
[SOS submission](screenshots/home-emergency-booking-submit.png).

The current [smart weather Home preview](screenshots/smart-weather-sky-background.png)
is rendered at 390 × 844 with bundled Montserrat, a blank avatar and demo weather.
Location selection now opens [address entry first](screenshots/home-location-search-first.png)
before [the retained confirmation screen](screenshots/home-location-confirmation-after-search.png).

`test/home_weather_service_test.dart` covers demo metadata, heat/rain precedence,
confirmed-location refresh, stale responses and failure/retry.
`test/smart_weather_rescue_card_test.dart` covers usable rescue controls during
weather failure/loading and 320px layouts with 1.5x text and a keyboard.
Home tests cover search/chip booking entry, preselected incidents, location-only
confirmation, retained Home State/scroll position and booking drafts,
blank-avatar/header placement, account/notification navigation and booking flows.
`test/home_video_hero_test.dart` continues to verify the separate legacy video widget.

Current Montserrat previews: [Home](screenshots/montserrat-home.png),
[Welcome](screenshots/montserrat-welcome.png),
[Location](screenshots/montserrat-location.png) and
[Account](screenshots/montserrat-profile.png).

Earlier previews used bundled Poppins with Noto Sans:
[Navigation selection](screenshots/revo-navigation-blue.png),
[Home](screenshots/revo-home-minimal.png),
[Filters](screenshots/revo-home-filters.png),
[Emergency services](screenshots/revo-home-services.png),
[Welcome](screenshots/revo-welcome.png),
[Login](screenshots/revo-login.png), [Registration](screenshots/revo-register.png),
[Recovery](screenshots/revo-forgot-password.png).
`test/welcome_screen_test.dart` verifies entry navigation, Back behavior, the
white/black auth palette and access to both actions at 320px with 1.5x text.

Earlier rendered previews (before the Poppins migration) are available for
[Home](screenshots/no-offers-home.png), [Account](screenshots/no-offers-account.png),
[Services](screenshots/be-services.png) and [Activity](screenshots/be-activity.png).
The dynamic request sheet preview is available
[here](screenshots/dynamic-rescue-request.png).

`test/home_discovery_service_test.dart` covers accent/service search, capability
filters, sorting and combined filters without mutating the source directory.
`test/home_screen_test.dart`, `test/trang_chu_test.dart` and
`test/home_provider_test.dart` cover reactive account data, navigation, picker
cancel/save, address validation and stale-coordinate removal, service selection,
request creation and duplicate blocking, GPS round-trip, station sorting and
empty states, plus 320px layouts with 1.5x text and the keyboard visible.
`test/create_rescue_request_bottom_sheet_test.dart` checks chip prices, the total
saved to an order, vehicle categories, camera previews/removal, cancellation,
errors and closing the sheet while a capture is pending.
