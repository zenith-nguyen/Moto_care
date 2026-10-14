# PR #38 customer UI integration review

PR #38 merges `feat/cam-thu/station-booking-layout` into `cam-thu`. It does not add the customer UI to `main` by itself. A separate reviewed `cam-thu` → `main` PR is required by the repository workflow.

## What this integration fixes

- Retains the `main` application entrypoint, session bootstrap, JWT token store, Socket.IO, push registration, and the provider/admin routes.
- Adds the customer UI behind the authenticated CUSTOMER route. The welcome, login, register, and password recovery screens use the real auth repository and session controller.
- Keeps customer routes inaccessible to signed-out, PROVIDER, and ADMIN sessions.
- Resolves the merge with `main`, removes accidental duplicate generated files, renames non-ASCII asset paths, and keeps Android/iOS plugin permissions and registrations together.

## Scope still requiring API integration before the customer flow is live

The UI branch includes local demo data sources for orders, chats, weather, and rescue stations. Examples are `activity_provider.dart`, `chat_directory_provider.dart`, `home_weather_provider.dart`, and `rescue_station_provider.dart`. Those screens can display demo values and must not be treated as confirmed backend orders, real conversations, weather pricing, or live station records. The next integration PR should bind these views to the existing customer repositories/controllers and show loading, empty, and error states. Payment/booking actions must use the backend order IDs and test-mode payment flow.

## Merge and verification

Before merging PR #38 into `cam-thu`, require green Flutter CI, green branch policy, and the requested code-owner approval. After merging, create and review the `cam-thu` → `main` integration PR only after replacing or explicitly marking demo-only data. Test login, registration, password recovery, role redirects, order/payment, chat, GPS, and reconnect on a device against the demo backend before release.
