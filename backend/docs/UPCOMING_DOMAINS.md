# Upcoming domains for Customer and Provider UI

Updated: 2026-10-11. This document separates UI-visible ideas from backend
capabilities that are already implemented. A screen must not be marked working
until its API, authorization and persistence are complete.

## Current delivery slice

The `feat/zenith/customer-profile-vehicles` slice provides editable name/phone,
Customer vehicle CRUD, one-default-vehicle enforcement, vehicle snapshots in
orders and protected tap-to-call contact. See
[PROFILE_VEHICLE_CONTACT_WORKFLOW.md](PROFILE_VEHICLE_CONTACT_WORKFLOW.md).

## Completed: Provider professional profile

Implemented persistence:

- extend `providers` with public bio, years of experience and service radius;
- `skills` catalog managed by Admin;
- `provider_skills` many-to-many relation with optional verification state;
- provider tier represented by an enum and changed only by a documented policy
  or Admin, never directly by the Provider client.

APIs cover own profile editing, public assigned-provider summary, skill selection
and Admin verification. Weekly Provider statistics are queried from orders,
reviews and wallet transactions for a requested week. They are not stored as
mutable counters, avoiding drift after refunds or Admin corrections. See
[PROVIDER_DIRECTORY.md](PROVIDER_DIRECTORY.md).

## Completed directory foundation: repair shops and charging stations

One `service_locations` aggregate now stores OSM/manual POIs with repair,
charging, fuel and parts types, contact/opening-hours metadata, active status and
`geography(Point,4326)` plus GiST index. Search supports viewport and distance.
The first snapshot importer is limited to TP.HCM and never treats OSM rows as
verified MotoCare partners. See
[SERVICE_LOCATION_MARKERS.md](SERVICE_LOCATION_MARKERS.md).

Booking slots, navigation/ETA, charging connector details and station-owner
self-service remain separate milestones because each adds new authorization and
consistency rules.

## Later: marketplace and spare parts

Keep marketplace isolated from rescue-order settlement:

- `product_categories`, `products`, `product_images` and seller-owned inventory;
- cart/checkout/order tables only after delivery, cancellation, refund and stock
  reservation rules are approved;
- every price uses `numeric`, inventory changes are transactional, and image
  objects use protected or explicitly public storage according to their role;
- SePay rescue payments must not be reused for marketplace money without a new
  payment purpose, idempotency key and reconciliation flow.

The first useful increment can be a read-only spare-parts catalog with filters.
It must not pretend that Buy/Checkout works while persistence and settlement are
absent.

## UI integration rule

The team may design these screens now, but should use loading/empty/error states
and feature flags. No production screen should depend on hard-coded mock users,
wallet balances, statistics, locations, inventory or prices. UI code will be
integrated only after the current Customer/Provider branches stabilize, following
the repository UI guardrails.
