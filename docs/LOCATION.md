# Incident location

Home's “Sửa vị trí” opens `/incident-location`. Both location screens use the
MotoCare light theme, peach header accents, white cards and orange `#FF6B35`
buttons. They retain the five main navigation tabs.

## Search and confirmation

`IncidentLocationSearchScreen` accepts an optional `RescueLocation` route extra.
Otherwise it starts with the previously confirmed location or the sample
`180/9a Bùi Văn Ba, Tân Thuận, Q.7`. The two inputs edit the address and a landmark
note. Recent places support Vietnamese searches without accents. Home/work
shortcuts use the saved profile addresses, with demo addresses as fallbacks.
Selecting a place or “Chọn trên bản đồ” opens `/incident-map-picker` with the
draft. Returning or cancelling search does not commit the draft. Changing an
address manually discards coordinates associated with the original address.

`IncidentMapPickerScreen` renders a local vector map on `#E9ECEF`. The orange SOS
pin stays centered above the draggable sheet while the map pans underneath.
Dragging selects one of the nearby sample addresses; there is no geocoding.
The circular GPS button restores `incidentCurrentLocationProvider`, which is an
injectable demo location. Sample addresses carry no fabricated coordinates.
There is no map SDK, network lookup, location permission or native GPS access.

“XÁC NHẬN VỊ TRÍ SỰ CỐ” validates and saves the address, landmark and optional
coordinate pair through `RescueLocationController.confirmLocation`, then opens
`CreateRescueRequestBottomSheet`. Closing that modal retains the confirmed
location and creates no order. Back navigation preserves the search draft.

## Request details

The modal uses the shared default vehicle, offers the existing add-vehicle form
for an empty garage, selects an emergency service and accepts an optional
incident description. It shows the selected address and landmark. Submission
requires a vehicle and location and is blocked while another active order
exists. `ActivityController.createOrder` stores the request once; the flow then
returns to Home, or Activity when entered through a direct route.

`RescueOrder.locationLandmark` and `incidentDescription` round-trip through JSON
and are retained when the status changes. Older records missing these fields
load with empty strings. Both notes are visible in Activity and order details.
Requests remain session-only prototypes: no mechanic is dispatched and no
payment is charged. Reference costs use the existing sample pricing boundary.

## Validation and previews

`test/incident_location_screens_test.dart` covers draft cancellation, shortcut
addresses, search filtering, map panning, GPS reset, sheet dragging, order
creation and duplicate blocking. It also exercises 320px screens, 1.5x text and
the keyboard. Home/provider/model tests cover shared location state, invalid
draft rejection, note preservation and compatibility with older order JSON.

Rendered previews: [search](screenshots/incident-location-search.png),
[map confirmation](screenshots/incident-map-picker.png) and
[request details](screenshots/incident-rescue-request.png).
