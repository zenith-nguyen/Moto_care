# PR #38 customer UI integration review

PR #38 merges `feat/cam-thu/station-booking-layout` into `cam-thu`. It does not add the customer UI to `main` by itself. A separate reviewed `cam-thu` → `main` PR is required by the repository workflow.

## What this integration fixes

- Retains the `main` application entrypoint, session bootstrap, JWT token store, Socket.IO, push registration, and the provider/admin routes.
- Adds the customer UI behind the authenticated CUSTOMER route. The welcome, login, register, and password recovery screens use the real auth repository and session controller.
- Keeps customer routes inaccessible to signed-out, PROVIDER, and ADMIN sessions.
- Resolves the merge with `main`, removes accidental duplicate generated files, renames non-ASCII asset paths, and keeps Android/iOS plugin permissions and registrations together.

## API integration status after PR #38

The follow-up `feat/cam-thu/customer-api-integration` branch replaces runtime demo sources for orders, rescue chat, notifications, weather and service locations. The production entrypoint explicitly enables API integration; widget tests retain deterministic fixtures without network access. Order creation/cancellation uses backend IDs, chat uses REST history plus Socket.IO resync and protected image downloads, weather only renders Open-Meteo responses, and stations come from PostGIS/OSM.

OSM locations remain informational. Because that source does not certify ratings,
completed jobs, opening state or MotoCare partnership, the UI hides those fields
and disables booking for those markers. It may still show directions and a call
button when a phone number exists.

## Merge and verification

Before merging PR #38 into `cam-thu`, require green Flutter CI, green branch policy, and the requested code-owner approval. After merging, create and review the `cam-thu` → `main` integration PR only after replacing or explicitly marking demo-only data. Test login, registration, password recovery, role redirects, order/payment, chat, GPS, and reconnect on a device against the demo backend before release.
