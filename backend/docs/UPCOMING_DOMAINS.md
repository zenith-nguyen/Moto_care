# Upcoming domains for Customer and Provider UI

Updated: 2026-10-11. This document separates UI-visible ideas from backend
capabilities that are already implemented. A screen must not be marked working
until its API, authorization and persistence are complete.

## Current delivery slice

The `feat/zenith/customer-profile-vehicles` slice provides editable name/phone,
Customer vehicle CRUD, one-default-vehicle enforcement, vehicle snapshots in
orders and protected tap-to-call contact. See
[PROFILE_VEHICLE_CONTACT_WORKFLOW.md](PROFILE_VEHICLE_CONTACT_WORKFLOW.md).

## Next: Provider professional profile

Planned persistence:

- extend `providers` with public bio, years of experience and service radius;
- `skills` catalog managed by Admin;
- `provider_skills` many-to-many relation with optional verification state;
- provider tier represented by an enum and changed only by a documented policy
  or Admin, never directly by the Provider client.

Planned APIs cover own profile editing, public assigned-provider summary, skill
selection and Admin verification. Weekly Provider statistics should be queried
from orders, reviews and wallet transactions for a requested week. They are not
stored as mutable counters, avoiding drift after refunds or Admin corrections.

## Later: repair shops and charging stations

Use one `service_locations` aggregate with a type (`REPAIR_SHOP` or
`CHARGING_STATION`), verified owner, contact, opening-hours data, active status
and `geography(Point,4326)` plus GiST index. Search is by distance and type.
Charging connector/power metadata belongs in a child table rather than generic
columns on every location.

The first version is a verified directory. Booking slots, navigation/ETA and
station-owner self-service are separate milestones because each adds new
authorization and consistency rules.

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
