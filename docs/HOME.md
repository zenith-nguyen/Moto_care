# Home screen

`/trang-chu` keeps its existing `TrangChu` entry point and renders the Riverpod
`HomeScreen` in `lib/features/home/screens/home_screen.dart`. Home uses
`HomeTheme.red`: a `#F8F9FA` background, white rounded cards, black text and red
accents (`#CC0001`), with white and gray curves in its header. Authentication uses the
same red accent through `AppTheme`. Supporting feature screens use the base
`HomeTheme.light` palette.

## Data and navigation

- Name, tier and reward points watch `profileProvider`. `UserProfile.rewardPoints`
  defaults to zero and round-trips through JSON. A `HomeUser` route payload seeds
  an uninitialized profile; an existing profile takes priority. Profile edits
  update the greeting without reopening the screen. The header hides the
  membership badge when its label is empty or the placeholder “Chưa có hạng”.
- The emergency vehicle watches `defaultVehicleProvider`. The picker uses the
  garage's `vehicleProvider` and `setDefault`, so selection is shared with the
  vehicle screen. Dismissal leaves the default unchanged. Empty garages offer
  the existing add-vehicle route.
- `rescueLocationProvider` starts unset. `initialRescueLocationProvider` is the
  integration boundary for an address and optional GPS coordinates. “Sửa vị trí”
  opens the [incident location flow](LOCATION.md): address and landmark search,
  a draggable map confirmation sheet, then rescue request details. Drafts do not
  update the shared location until confirmation. Typed address changes clear
  stale coordinates. The map and current-location shortcut use sample data;
  no native GPS or address geocoding is connected yet.
- The light bottom bar contains Home, Activity, Services (`/dich-vu`), Vouchers
  and Account (`/tai-khoan`). Moving between secondary tabs replaces the current
  tab above Home, so returning preserves the existing Home page. The Home menu button and drawer have been removed. Vehicles,
  Messages and all former menu destinations are available from Account; rescue stations are also
  accessible from Services and Home's nearby section.
- All eight service tiles open `PartnerListScreen` at `/partners`, passing the
  tile title as `serviceType`. The [marketplace flow](MARKETPLACE.md) then selects
  a shop and packages, checks out and tracks the saved order. Club, offer cards,
  tips and station cards open their corresponding features. The Services tab
  still opens `/dich-vu`.
- `PromoBannerSlider` sits below the header, before the service grid. Its three
  banners display `assets/images/Banner1.png`, `Banner2.png` and `Banner3.png`
  in that order with rounded corners. The slider follows the first image's
  736:414 aspect ratio; each image keeps its original proportions and fits
  entirely within the frame without cropping. Users
  swipe horizontally; automatic paging runs every four seconds and loops back
  to the first banner. Three dots show the current page in red. Banners and
  dots have no tap actions. Automatic paging pauses during scrolling, while
  the app is in the background, and when the home route is hidden.

The Home header has no search button. The service grid uses the label “Vá xe”.
All eight service icons use the red brand accent (`#CC0001`). Primary text is
`#111827` and secondary text is `#4B5563`.

## Supporting request sheets and nearby stations

Home booking uses the [marketplace flow](MARKETPLACE.md). The existing supporting
request sheet used by location/catalog entry points is described below.

The dynamic request sheet offers service-specific choice chips: tire repair at
30k/50k/90k, battery assistance at 40k/280k, fuel delivery at 45k/85k and flooded
engine repairs at 60k/120k. Both “Vá xe” and “Vá xe / Săm” select the tire options.
Other services offer an on-site inspection and rescue at 50k. Selecting a chip
updates the total immediately, with the first option selected initially.

The form retains the shared garage picker and adds vehicle categories (scooter,
underbone and manual/large-displacement bikes), an optional camera attachment
with preview/removal, and the incident description. It watches the current
address, optional coordinates and active orders. The red “TÌM THỢ CỨU HỘ NGAY”
button is disabled without vehicle/location or while an active request exists.

Confirmation calls `ActivityController.createOrder` and retains the service,
vehicle, selected option/category, selected price, address, landmark and optional
coordinates in a pending `RescueOrder`. Camera bytes remain in memory for the
session and survive status changes, but are not serialized to JSON. The order
appears in Activity. Cancelling/dismissing the sheet creates nothing; an active
order prevents duplicate requests. Maintenance currently records a service
request; appointment slots and scheduling are not connected.

These requests are session-only prototypes. The confirmation explicitly states
that no mechanic is dispatched and no payment is charged. The dynamic sheet uses
the displayed option prices; other request flows retain the existing mock
pricing boundary. Actual costs need station confirmation.

Nearby cards consume `rescueStationsProvider`. With GPS coordinates they sort by
straight-line distance; without coordinates they use the directory's reference
distances. The directory is still sample data and the UI labels it accordingly.
No live road distances or availability service is connected. The empty directory
has a dedicated message. Offer banners are examples and link to the existing
voucher screen for terms.

## Validation

Rendered previews with the bundled Roboto fonts are available for
[Home](screenshots/light-home.png), [Account](screenshots/be-profile.png),
[Services](screenshots/be-services.png) and [Activity](screenshots/be-activity.png).
The dynamic request sheet preview is available
[here](screenshots/dynamic-rescue-request.png).

`test/home_screen_test.dart`, `test/trang_chu_test.dart` and
`test/home_provider_test.dart` cover reactive account data, navigation, picker
cancel/save, address validation and stale-coordinate removal, service selection,
request creation and duplicate blocking, GPS round-trip, station sorting and
empty states, plus 320px layouts with 1.5x text and the keyboard visible.
`test/promo_banner_slider_test.dart` also covers swipe navigation, the four-second
interval and wraparound, idle taps, timer reset after swiping, lifecycle pauses,
large text and cleanup on disposal.
`test/create_rescue_request_bottom_sheet_test.dart` checks chip prices, the total
saved to an order, vehicle categories, camera previews/removal, cancellation,
errors and closing the sheet while a capture is pending.
