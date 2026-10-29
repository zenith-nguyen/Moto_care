# Profile, vehicle and participant-contact workflow

Updated: 2026-10-11.

This contract prepares the Customer and Provider UI without importing either
UI branch. REST remains the source of truth; screens must not keep a separate
mock profile or vehicle store.

## Editable profile

- `GET /users/me` returns the authenticated profile.
- `PATCH /users/me` accepts `name`, `phone`, `emergencyContactName`,
  `emergencyContactPhone`, `medicalNote`, `homeAddress` and `workAddress`.
- Email, role, status and security fields cannot be changed through this
  endpoint. Email changes need a separate verification flow later.
- Emergency, medical and address fields are nullable, length-limited and
  persisted in PostgreSQL. Empty optional values clear the corresponding
  column.
- Phone is normalized and must contain 9–15 digits with an optional leading
  `+`. A duplicate phone returns `409`.

## Customer vehicles

Customer-only endpoints:

- `GET /users/me/vehicles`
- `POST /users/me/vehicles`
- `PATCH /users/me/vehicles/:vehicleId`
- `DELETE /users/me/vehicles/:vehicleId`

Supported types are `MOTORBIKE`, `ELECTRIC_MOTORBIKE`, `CAR` and `OTHER`.
License plates are normalized to uppercase and unique. The first vehicle is
always the default. Setting another vehicle as default is atomic, and deleting
the default promotes the oldest remaining vehicle. An existing default cannot
be unset without choosing another one, so a customer with vehicles always has
exactly one default.

`POST /orders` accepts optional `vehicle_id`. If omitted, the current default
vehicle is used when one exists. The order stores a snapshot of type, brand,
model, license plate and color. Editing or deleting the profile vehicle later
does not change an existing order. `sourceVehicleId` may become `null` after
deletion while the snapshot remains available.

## Tap-to-call privacy rule

The regular order, offer and history payloads do not contain participant phone
numbers. When the user taps **Call**, the app requests:

`GET /orders/:orderId/participant-contact`

The endpoint returns the other participant's direct phone only when all rules
hold:

1. a provider has accepted and is assigned to the order;
2. the caller is that order's Customer or assigned Provider;
3. the order is active (`ACCEPTED` through `PAID`, including price review and
   dispute states).

Pending offers, unrelated accounts and closed/cancelled/refunded orders cannot
retrieve the phone. If the account has no phone, the response returns
`phone: null` and the UI disables the call action. The Flutter UI may then open
the operating-system `tel:` action. MotoCare does not proxy or record calls;
that would require a separate paid telephony service and consent policy.

## Database guarantees

- Foreign keys protect vehicle ownership and order references.
- A partial unique index permits only one default vehicle per customer.
- A check constraint requires every order vehicle snapshot to be either fully
  present or fully absent.
- Deleting a vehicle sets `orders.vehicle_id` to null but intentionally keeps
  snapshot columns for audit/history.

## Deferred domains

Provider skills/tier/statistics, service stations and marketplace/spare parts
are separate domains. They must not be represented as extra vehicle/profile
columns. The next backend slice adds Provider profile/skills and weekly stats;
stations and marketplace follow after their ownership, inventory and ordering
rules are documented.
