# Service and support screens

`/dich-vu` opens the light `ServicesScreen`, available from the bottom tab and
Home's All services tile. Its SOS grid has three columns and six services: tire,
battery, fuel, flooding, towing and night rescue. The utility grid has four
columns for the four requested utilities: maintenance, nearby places, prices and
self-help tips. It does not add blank tiles or extra unspecified services.

Rescue and maintenance tiles reuse Home's confirmation sheet and shared selected
vehicle/location. Confirmation creates a session-only pending order; it is
disabled if context is missing or an active order exists. Night rescue has its
own service type and reference estimate. Maintenance still records a request;
appointment scheduling is not connected. Other tiles open the existing routes.
`test/be_screens_test.dart` verifies routing, cancel/create behavior, GPS/vehicle
retention, missing context and narrow layouts.

The Account menu and Services tiles open the following supporting `go_router`
routes. These screens use the shared light background, white cards, dark text
and orange accents. `ServiceScaffold` retains the four Home navigation tabs below
any fixed form or support actions. `/kho-voucher` and `/tich-diem` have been
removed along with the offers, points and membership modules.

| Route | Feature |
| --- | --- |
| `/tram-sac-tiem-sua` | Address search, combined filters, interactive mock map and service list |
| `/bang-gia` | Searchable service and part prices grouped in expansion tiles |
| `/dang-ky-tho` | Three-step partner registration, identity photos, experience, tools and area |
| `/cam-ket-dich-vu` | Service commitments and compensation form using recent activity orders |
| `/faq` | Searchable questions, topic filters, hotline and message navigation |
| `/meo-xu-ly` | Four illustrated emergency articles displayed in scrollable bottom sheets |

Light previews: [Help](screenshots/light-help.png) and
[Messages](screenshots/light-messages.png).

## Prototype boundaries

- Service places, distances, ratings, opening status and map markers are mock data.
  There is no geolocation, Google Maps SDK or live address lookup. Search matches
  the local name/address list, including input without Vietnamese accents.
- Filters intersect. Directions launch an external Google Maps destination URL.
  Demo places have no invented phone numbers; their Call button explains this.
  Supply real places through `servicePlacesProvider` to enable `tel:` calls.
- The FAQ hotline uses the existing registration-screen contact, `1130`, via
  `supportHotlineProvider`. Confirm the production support number and operating
  hours before release. Chat opens `/tin-nhan` as requested.
- Partner and compensation submissions are immutable Riverpod records retained
  only in memory for the current `ProviderScope`. Forms explicitly disclose the
  trial state; no request reaches Admin or an insurer and there is no actual
  24-hour verification workflow. Restarting the app discards these records.
- Partner registration requires a name, 12-digit CCCD, both photos, experience,
  at least one tool and an operating area. Listed districts are example service
  zones, not an authoritative administrative directory. Compensation requires
  a recent non-cancelled order and a description of at least 10 characters;
  evidence is optional. A submitted form cannot submit again in the same screen.
- Existing `image_picker` selects photos with previews and removal, handles cancel
  and errors, and limits photos to 5 MB. Bytes remain in memory and are not uploaded.
  No credentials or identity images are written to disk by these features.
- `serviceUrlLauncherProvider` and `attachmentPickerProvider` are injectable for
  widget tests and eventual native/service integrations. No new packages or
  platform configuration were added.

## Emergency guidance

Thumbnails and numbered step images are local Flutter vector illustrations. The
articles use conservative guidance: stop safely, avoid repeatedly starting a
flooded engine, avoid riding on a flat tire, and contact a mechanic. Gear reduction
is scoped to suitable geared motorcycles and trained riders; scooters are excluded.

Sources linked from the articles:

- [Honda Vietnam usage FAQ](https://www.honda.com.vn/cau-hoi-thuong-gap?category=thong-tin-ve-cong-ty&category_child=tu-van-su-dung-xe-may&category_tab=su-dung-xe)
- [California DMV Motorcycle Handbook](https://www.dmv.ca.gov/portal/file/motorcycle-driver-handbook-pdf/)
- [Honda SH Mode owner's manual](https://2rom-prd-data.hondamotopub.com/om/HVN/SH%20Mode/2019/SH%20Mode_4FK29A30_0.pdf)

The articles are not a substitute for the specific vehicle's owner's manual or
hands-on training. Commercial policy terms and sample data require product
approval and backend integration before production use.

## Validation

`test/service_screens_test.dart` covers menu routing and account preservation,
removed offer/membership routes, combined place filters and external-launch
fallbacks, price search, form validation/photo selection/session
submission, empty orders, FAQ actions, article steps and 320px layouts with 1.5x text.
