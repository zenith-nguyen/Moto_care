# Vehicles and rescue stations

Account opens `/xe-cua-toi`; the “Bản đồ trạm” tab opens
`/tram-cuu-ho?view=map` directly in map mode. Services can still open the station
directory in list mode. Both screens use the shared light service scaffold and
the four floating tabs: Home, Station map, Activity and Account. The garage
highlights Account and the directory highlights Station map. Returning to Home
preserves the current account and Home search.
The directory is a main tab: its centered 18px title has no Back button;
other service screens retain their existing Back navigation.
The directory uses `assets/images/background.png` behind the transparent header
and scrolling content in both list and map modes. Text stays opaque and dark;
search fields and station cards retain their white surfaces for readability.

## Vehicle module

`lib/features/vehicle/` contains the immutable `Vehicle` model, validation,
Riverpod controller, garage screen, vehicle card and add/edit bottom sheet.

- Model fields: `id`, `name`, `brand`, `licensePlate`, `tireType`, `engineType`,
  `isDefault`, `color`. Tire and engine enums serialize to the requested wire values
  `tubeless`/`tubed` and `gas`/`electric`. `fromJson`/`toJson` require no code generation.
- `vehicleProvider` starts empty. `initialVehiclesProvider` can supply a saved/API
  list and `defaultVehicleProvider` exposes the selected rescue vehicle.
- The controller adds, edits, sets defaults and deletes by ID. The first vehicle
  becomes default automatically. Only one vehicle is default; deleting it promotes
  the first remaining vehicle. Editing preserves ID/default status.
- Required fields are name, plate and brand. Plates are uppercased for display;
  duplicate checks ignore whitespace, dots, dashes and case. Validation checks
  basic input quality rather than claiming legal validation of registration plates.
- The bottom sheet supports both tire/engine choices and an optional color field.
  It preserves unfamiliar brands supplied in existing data. Closing or dismissing
  the form leaves state unchanged. Deletion requires confirmation.
- Vehicle records and lists are immutable. This implementation stores vehicles
  in the current Riverpod session, including across tab navigation. It does not
  persist across app restarts or send records to a backend. Connect an authenticated
  repository or approved durable storage when that integration is requested.

## Rescue station module

`lib/features/rescue_station/` separates the immutable model, sample data,
filtering provider, screen, list/map widgets and native actions.

Tapping a station card in either mode now opens the
[station detail screen](STATION_DETAILS.md), passing its typed model and preserving
the selected station ID. The card's existing call and direction buttons remain
independent actions.

- Model fields match the requested station data. `stationType` is a typed enum
  serialized as `partner`, `official_dealer` or `mobile_team`. An additional
  `isOpen` flag distinguishes closed non-24-hour stations without inferring hours.
- Names, addresses, contacts, coordinates, distances, ratings, counts and badges
  are demonstration data. There is no live location, verification service, opening
  schedule lookup or Google Maps SDK. The map retains its simulation label.
- `rescueStationsProvider` is injectable for API integration/tests. Address/name
  search accepts Vietnamese without accents. 24-hour, verified and official-dealer
  filters intersect. `Gần nhất` sorts by ascending mock distance; otherwise results
  sort by descending rating. Filters and search apply to both viewing modes.
- The list uses `ListView.builder`. The mock map projects sample coordinates to
  clickable markers and shows the selected station card. Zero results have a
  shared empty state, including in map mode.
- Home tiles and list/map cards share `StationCardPhoto`, the existing Home image
  assets, crop, gradient, blue verification badge and response/rating pills.
  `AppTextStyles` and `AppCardLayout` in `app_theme.dart` supply the shared 16px
  card title, 13px body, 12px caption, line heights, spacing and 16px photo radius.
  Directory cards retain station type, verification, full address, opening status,
  completed rescue count, distance, detail navigation and both native action buttons.
  Review counts come from Home metadata and are distinct from completed rescues.
  Search, all filters (including nearest sorting) and the list/map toggle are retained;
  only the result/sort summary and the directory's sample-information sentence are removed.
- Call opens `tel:phoneNumber`; Directions opens a Google Maps URL with station
  latitude/longitude. `serviceUrlLauncherProvider` is the existing injectable
  `url_launcher` boundary. Failed launches show contact/address information.
  Sample phone numbers and positions must be replaced with real directory data
  before offering production rescue service.

Review capture: [restored station map](screenshots/station-map-restored.png).
Directory card capture: [shared Home photo and typography](screenshots/station-directory-home-style.png).
Background capture: [station directory over the blue image](screenshots/station-directory-background.png).

## Validation

- `test/vehicle_provider_test.dart`: model wire values, immutable CRUD, duplicate
  plates, default changes and promotion after deletion.
- `test/rescue_station_test.dart`: model bounds/JSON, accented search, combined
  filtering and sorting without changing source data.
- `test/vehicle_rescue_station_screen_test.dart`: tab routing/account preservation,
  empty garage, validated add/edit/cancel/delete flows, state across navigation,
  station filters/map selection, external-launch fallbacks and 320px layouts with
  1.5x text and the keyboard open.
