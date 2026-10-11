# TP.HCM service-location map markers

Updated: 2026-10-11.

MotoCare's no-cost demo uses an OpenStreetMap snapshot for informational markers.
It does not scrape Google Maps, require a Google key or enable Google billing.
Google Places may later implement a separate source adapter, but it must remain
disabled by default and must receive its key from server-side configuration.

## Marker categories

- `REPAIR_SHOP`
- `CHARGING_STATION`
- `FUEL_STATION`
- `PARTS_STORE`

OSM rows have `source=OSM`, `isVerified=false` and `isPartner=false`. They are not
MotoCare accounts, do not receive orders and must not be presented as endorsed
businesses. Missing names are skipped. An import updates rows by the unique
`(source, source_id)` pair and deliberately does not delete missing rows after a
partial or failed upstream response.

## Importing a TP.HCM snapshot

With Docker/PostGIS running and migrations applied:

```powershell
cd D:\mobile_app_motocare\mobilecare_1\backend
npm run locations:import-osm
```

The default source is the public HTTPS Overpass endpoint and the default bounding
box is limited to TP.HCM. Optional local environment variables are:

- `OSM_OVERPASS_URL`: alternate HTTPS Overpass endpoint.
- `OSM_IMPORT_BBOX`: `south,west,north,east`.

This is a manual setup command, not an application request path or scheduled job.
Do not run it for every map movement. Public Overpass is best-effort and can be
busy; a failed/empty import leaves existing rows untouched.

## Flutter API contract

All routes require the normal Bearer JWT.

```http
GET /service-locations/viewport
  ?north=10.82&south=10.75&east=106.73&west=106.68
  &types=REPAIR_SHOP,CHARGING_STATION
```

Returns at most 200 active markers in a viewport no larger than one degree in
either direction. Flutter should debounce map movement by roughly 500–800 ms and
cancel an older in-flight request when a newer viewport is requested.

```http
GET /service-locations/nearby
  ?latitude=10.7769&longitude=106.7009
  &radius_km=5&limit=50
  &types=REPAIR_SHOP,CHARGING_STATION
```

Returns at most 100 markers ordered by straight-line PostGIS distance. Radius is
0.1–50 km. `distanceMeters` is rounded to an integer.

The UI may show name, category, address, opening hours and contact data supplied
by OSM. It should label unverified data as “Thông tin tham khảo”, offer a refresh
or empty state, and never imply live availability. A directions button may open
an external map application by coordinates; MotoCare does not provide routing or
ETA for these POIs.

The map must visibly attribute `© OpenStreetMap contributors` and follow the OSM
tile usage policy. Do not bulk-download map tiles or hide attribution.
