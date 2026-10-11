# Provider professional profile and weekly statistics

Updated: 2026-10-11.

This module separates professional identity from Provider presence. Online status,
GPS and matching remain in the existing presence service. A Provider cannot edit
their approval status, account status, tier or skill verification result.

## Data model

- `providers`: public biography, years of experience, service radius and tier.
- `skills`: Admin-managed catalog with stable code, display name and active flag.
- `provider_skills`: unique Provider/skill claim with `PENDING`, `VERIFIED` or
  `REJECTED` status.
- `ProviderTier`: `STANDARD`, `SILVER`, `GOLD`, `PLATINUM`. Only Admin changes it.

Service radius is a decimal kilometre value between 1 and 100. Experience is an
integer from 0 to 70. These constraints exist in DTO validation and PostgreSQL.

## Provider flow

1. Read active skill choices with `GET /provider-skills`.
2. Read/edit professional fields with `GET/PATCH /providers/me/profile`.
3. Replace skill claims with `PUT /providers/me/skills` and `{ "skillIds": [...] }`.
4. New claims are `PENDING`. Re-selecting a rejected claim returns it to
   `PENDING`; verified claims stay verified.
5. Read derived weekly statistics with
   `GET /providers/me/statistics/weekly?week_start=YYYY-MM-DD`. The date must be a
   Monday in `Asia/Ho_Chi_Minh`; omit it for the current week.

Weekly values are derived from completed orders, received reviews and immutable
wallet transactions. No mutable weekly counters are stored, so Admin corrections
and ledger changes do not leave a second source of truth. Amounts are decimal
strings.

## Admin flow

- `GET/POST /admin/provider-skills`
- `PATCH /admin/provider-skills/:skillId`
- `PATCH /admin/providers/:providerId/tier`
- `PATCH /admin/providers/:providerId/skills/:skillId/verification`

Deactivating a catalog item prevents new claims and verification. It does not
delete history.

## Customer-visible summary

`GET /orders/:orderId/provider-profile` returns the assigned Provider's name,
professional fields, tier, verified skills and aggregate rating. It is available
only to that order's Customer and assigned Provider after assignment. It never
contains email, phone or private documents. Direct phone access remains isolated
behind `GET /orders/:orderId/participant-contact` when the user taps Call.
