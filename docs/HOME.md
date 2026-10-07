# Home screen

`/trang-chu` keeps its existing `TrangChu` entry point and renders the Riverpod
`HomeScreen` in `lib/features/home/screens/home_screen.dart`. The home theme is
shared with the new Account, Services and Activity screens: `#F8F9FA` background,
white rounded cards, black text, orange and red accents. Soft orange curves in
Home and Account headers follow the supplied Be layout references. Supporting
feature screens share the same light palette, including authentication, profile
details, vouchers, chat and order details.

## Data and navigation

- Name, tier and reward points watch `profileProvider`. `UserProfile.rewardPoints`
  defaults to zero and round-trips through JSON. A `HomeUser` route payload seeds
  an uninitialized profile; an existing profile takes priority. Profile edits
  update the greeting without reopening the screen.
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
- Charging opens the existing places screen. All services opens `/dich-vu`. Club,
  promotional banners, tips and station cards open their corresponding features.

Home search starts with an empty prompt and searches service names only, including
Vietnamese input without accents. Selecting a result opens the existing service
confirmation or catalog/places route. It does not show account or menu links.

## Rescue requests and nearby stations

Six request services open a confirmation sheet: tire repair, battery jump,
out-of-fuel, flooded engine, towing and maintenance. The sheet watches the
current vehicle, address, optional coordinates and active orders. Submission is
disabled without vehicle/location or while an active request exists.

Confirmation calls `ActivityController.createOrder` and retains the service,
vehicle, address, landmark and optional coordinates in a pending `RescueOrder`. The order
appears in Activity. Cancelling/dismissing the sheet creates nothing; an active
order prevents duplicate requests. Maintenance currently records a service
request; appointment slots and scheduling are not connected.

These requests are session-only prototypes. The confirmation explicitly states
that no mechanic is dispatched and no payment is charged. Reference prices come
from the existing mock pricing boundary; actual costs need station confirmation.

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

`test/home_screen_test.dart`, `test/trang_chu_test.dart` and
`test/home_provider_test.dart` cover reactive account data, navigation, picker
cancel/save, address validation and stale-coordinate removal, service selection,
request creation and duplicate blocking, GPS round-trip, station sorting and
empty states, plus 320px layouts with 1.5x text and the keyboard visible.
