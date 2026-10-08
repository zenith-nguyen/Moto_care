# Incident location: Places search and Google Maps

Home's “Sửa vị trí” opens `/incident-location`. The two screens use MotoCare's
white/gray surfaces, dark text and red `#CC0001` primary controls.

## Search and camera flow

`SelectLocationScreen` (`select_location_screen.dart`) accepts a draft
`RescueLocation`. `incident_location_search_screen.dart` exports the old class
name for existing callers. The address starts from an explicit draft or a
previously confirmed location; no sample address or fabricated GPS is injected.

Typing triggers a 300 ms debounce and an HTTP Places Autocomplete (New) request.
Suggestions appear directly below the address field with a title and detailed
address. Queries keep their Vietnamese spelling; Google handles name/substring
matching. The API requests Vietnamese results in Vietnam, optionally biased by
the draft's GPS coordinates. Each search session uses a random session token
shared by autocomplete and its Place Details call. A subsequent selection uses
a fresh session token. Editing, clearing or leaving the screen cancels pending
requests; revision checks also ignore responses from a service that fails to
honor cancellation. Errors and empty results do not commit a draft.

Selecting a suggestion resolves its real coordinates through Place Details.
Manual addresses and saved home/work shortcuts use forward geocoding when
configured. Empty home/work shortcuts are disabled. The current-location action
uses `deviceLocationProvider`, including real foreground permission handling,
GPS timeouts and a coordinate fallback when native address resolution fails.
Recent locations are confirmed user selections held in session memory.

`IncidentLocationScreen` (`incident_location_screen.dart`) uses
`google_maps_flutter`; `incident_map_picker_screen.dart` retains the old class
alias. Its search button pushes `/incident-location?pick=1`. Selecting a result
pops a `RescueLocation` back to that existing map. The screen updates its address
draft and calls `GoogleMapController.animateCamera` with
`CameraUpdate.newCameraPosition(CameraPosition(target: newLatLng, zoom: 17))`.
If the controller is not ready yet, the newest selected coordinate is applied
when it becomes available. The original Home search entry can still open the
map with its draft and restore its fields on Back.

The native map occupies the visible area above the draggable sheet, so its
camera center and the SOS pin's tip refer to the same coordinate. Map attribution
remains visible. Dragging updates the camera coordinate; on idle, reverse
geocoding resolves its address. Reverse-geocoded addresses retain the exact
camera coordinates, even if the provider returns a nearby street's coordinate.
Moving again, choosing another place, using GPS or leaving cancels the old lookup.
A failed reverse lookup keeps the actual coordinate label instead of an old
address. Confirmation is disabled while the camera/GPS/address lookup is busy.

With no map key, or on desktop/web, the screen shows an unavailable-map message
and still supports search/GPS. It never renders the former sample map as a real
map. Android and iOS are the supported native map targets. The default city
viewport (10.762622, 106.660172) is only a starting view and never substitutes for
an incident location. Address-only legacy drafts remain usable without the SDK;
confirmation with an enabled map requires an actual selected coordinate.

## API configuration

No real credentials are included. Copy `config/maps.example.json` to the ignored
`config/maps.local.json`, then fill the values for your Google Cloud project.
Use separate, restricted SDK and web-service keys. Enable Places API (New),
Geocoding API and the Maps SDK for each native platform in that project.

| Setting | Purpose |
| --- | --- |
| `GOOGLE_PLACES_API_KEY` | Places autocomplete/details in direct development mode. |
| `GOOGLE_GEOCODING_API_KEY` | Forward/reverse geocoding; defaults to the Places key when empty. |
| `GOOGLE_MAPS_ANDROID_API_KEY` | Android Maps SDK; Gradle decodes this Dart define into the manifest placeholder. |
| `GOOGLE_MAPS_IOS_API_KEY` | iOS Maps SDK; also populate local Xcode settings with the helper below. |
| `GOOGLE_ANDROID_CERT_SHA1` | App signing SHA-1 for the direct REST `X-Android-Cert` header; colons are removed. |
| `PLACES_PROXY_URL` | Optional authenticated backend base URL that mirrors the `/v1` Places paths, e.g. `https://your-api/places/v1`. |
| `GEOCODING_PROXY_URL` | Optional backend endpoint that mirrors the Geocoding JSON response. |

Run Android:

```sh
flutter run --dart-define-from-file=config/maps.local.json
```

Before running iOS, generate the ignored native settings from the same local file:

```sh
python3 tool/configure_maps_ios.py
flutter run --dart-define-from-file=config/maps.local.json
```

The helper does not print the key. `Debug.xcconfig` and `Release.xcconfig`
optionally include `MapsKeys.xcconfig`; `Info.plist` passes its SDK key to
`GMSServices.provideAPIKey`. The SDK 9 implementation supports the repository's
Swift Package Manager setup and existing iOS 15 target. Hot reload cannot apply
native credentials or newly added plugins; restart/rebuild the application.

`GooglePlacesService` uses the feature's shared injectable Dio client with bounded
connect/send/receive timeouts. There is no key/body logging. Direct Android/iOS
REST requests carry application restriction headers. For production, use the
proxy settings and override `locationDioProvider` with the application's
authenticated client. The proxy must add its server key, validate allowed
operations and authenticate callers; no proxy backend is created by this change.
Google keys are never forwarded to configured proxy endpoints.

Requests and responses:

| Operation | Provider request | Fields used |
| --- | --- | --- |
| Autocomplete | `POST /v1/places:autocomplete` | Place ID, main title, secondary address. |
| Details | `GET /v1/places/{placeId}` | Formatted address, latitude, longitude. |
| Forward geocoding | `GET /maps/api/geocode/json?address=...` | Formatted address and valid coordinate pair. |
| Reverse geocoding | Same endpoint with `latlng=...` | Address; incident retains the camera coordinate. |

Official references: [Autocomplete](https://developers.google.com/maps/documentation/places/web-service/place-autocomplete),
[Place Details](https://developers.google.com/maps/documentation/places/web-service/place-details),
[Geocoding](https://developers.google.com/maps/documentation/geocoding/guides-v3/requests-geocoding),
[Flutter Maps setup](https://pub.dev/packages/google_maps_flutter), and
[direct calls/proxies](https://developers.google.com/maps/api-security-best-practices#secure-client-side-web-service-calls).

## Confirmation and rescue request

“XÁC NHẬN VỊ TRÍ SỰ CỐ” saves the address, landmark and coordinate pair through
`RescueLocationController.confirmLocation`, remembers the location, then opens
`CreateRescueRequestBottomSheet`. Closing that modal retains the confirmed
location and creates no order. Search cancellation does not save its draft.

The supporting request modal retains the shared garage vehicle, service selection,
notes and optional in-memory incident photo. Submission is blocked without a
vehicle/location or while another active order exists. Saved notes and GPS
coordinates round-trip through order JSON and remain when the status changes.
Requests are session-only: mechanic dispatch and payment still require a backend.
Marketplace checkout continues to use the shared confirmed location.

## Validation

`test/places_service_test.dart` exercises actual Dio requests through a controlled
HTTP adapter: methods, endpoints, Vietnamese/session/bias parameters, coordinates,
errors, cancellation and proxy key isolation. `test/location_autocomplete_test.dart`
checks debounce timing, stale autocomplete/details/GPS/reverse responses, returned
route data, camera zoom/target, late controller creation, draft-only selection,
confirmation, disposal and 320px / 1.5x text / keyboard layouts. Native map events
are supplied through a controllable camera adapter in widget tests.
The existing location/order tests cover the supporting rescue flow.

Review images: [autocomplete](screenshots/location-autocomplete.png) and
[selected location](screenshots/location-map-selected.png). These captures use
controlled Places responses and a camera test adapter. The second image labels
its empty map area explicitly; neither capture is evidence of live Google data.

The implementation passed all 208 tests, `flutter analyze --no-pub`, and the
repository's Dart formatting check. `flutter build apk --debug --no-pub`
successfully produced `build/app/outputs/flutter-apk/app-debug.apk`.
The local iOS configuration helper was also
checked for valid input, rejection of injected settings, and key-free output.
An iOS native build was not run because this environment has Command Line Tools
but no Xcode installation.

Live Google requests, map tiles and physical-device GPS require configured keys
and device validation; mocked tests do not verify account billing or restrictions.
