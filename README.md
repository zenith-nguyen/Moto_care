# Moto Care

Moto Care is a mobile roadside-assistance application for motorbike riders. It connects customers who need help with nearby approved mobile mechanics.

This repository is the MotoCare monorepo. The Flutter mobile application lives at the repository root, and the NestJS API lives in `backend/`.

The backend uses PostgreSQL + PostGIS locally through Docker Compose. See [`backend/README.md`](backend/README.md) for backend setup and database commands.

## Product scope

Customers can request help for incidents such as an empty fuel tank, flat tire, engine failure, dead battery, or minor collision. Before confirming a request, the application shows a transparent estimated price. After a mechanic accepts the request, the customer can track the mechanic in real time, chat, confirm the service by QR code, pay, and leave a review.

The application supports three roles:

- **Customer**: creates SOS requests, tracks a mechanic, chats, pays, reviews, and views service history.
- **Provider**: accepts nearby requests, manages service progress and extra costs, views earnings, and requests withdrawals. Providers must be approved by an administrator before accepting requests.
- **Administrator**: approves providers, reviews platform activity, handles complaints, and processes withdrawal requests.

## Mobile technology

- Flutter and Dart
- Riverpod for application state
- Go Router for navigation
- Dio for backend communication
- Secure Storage for credentials and tokens
- Flutter localization and `intl` for Vietnamese dates, currency, and UI

## Delivery target

The project started as a one-month mobile-development course project whose
required deliverable was an Android APK. It is now feature-complete: the two
Android apps, the NestJS API, real SePay bank-transfer payments and the admin
console all run against one deployment (see [Release builds](#release-builds)
and [`GO-LIVE.md`](GO-LIVE.md)).

## Documentation

Project guides, contribution rules, AI instructions, CI/CD, and release procedures are maintained in [`docs/`](docs/README.md).

## Run locally

The Android build declares two flavors, so a flavor and an entrypoint are always
required. `API_BASE_URL` defaults to `http://10.0.2.2:3000` (the host machine as
seen from an Android emulator) in debug builds.

```bash
flutter pub get

# Customer app
flutter run --flavor customer -t lib/main.dart

# Provider (mechanic) app
flutter run --flavor provider -t lib/main_provider.dart
```

The admin console is not a separate app: signing in with an `ADMIN` account
inside the customer app opens the admin shell.

## Release builds

Release APKs are signed with the keystore described by `android/key.properties`
(git-ignored, created from [`android/key.properties.example`](android/key.properties.example)).
Without that file the release build falls back to the debug keystore, which is
fine for sideloading but not for Google Play.

```bash
flutter build apk --release --flavor customer -t lib/main.dart \
  --dart-define=API_BASE_URL=https://your-backend.example.com

flutter build apk --release --flavor provider -t lib/main_provider.dart \
  --dart-define=API_BASE_URL=https://your-backend.example.com
```

Artifacts land in `build/app/outputs/flutter-apk/`. `API_BASE_URL` is mandatory
in release mode and must be HTTPS; the app refuses to start without it.

Pushing a `v*.*.*` tag that matches `pubspec.yaml` runs
[`release-android.yml`](.github/workflows/release-android.yml), which builds both
APKs and attaches them to a public GitHub release. It reads the backend URL from
the `API_BASE_URL` repository variable and fails if that variable is missing.
Keep the keystore and its passwords out of the repository, and remember that a
published APK exposes whichever backend URL it was built with.

## Deployment and go-live

The backend can run on any public HTTPS host. [`GO-LIVE.md`](GO-LIVE.md) is the
operations runbook: it documents exposing the local backend publicly (Tailscale
Funnel), the test → live switch, SePay webhook registration, and building the app
against the public URL. `backend/Dockerfile` (multi-stage, runs migrations then
starts) plus the `start:prod` / `migration:run:prod` scripts cover a container
deploy (Render/Railway/Fly).

Swagger UI is served at `/docs` in non-production, and can be enabled in
production for a demo with `SWAGGER_ENABLED=true`.

Money safety: real-money payment acceptance (`SEPAY_MODE=live`) and provider
payouts are deliberate, owner-confirmed steps. Payouts stay manual; the system
never transfers real money automatically.

## Startup and authentication UI

Android and iOS show a white native splash screen with Revo branding. Once
Flutter is ready, `/` redirects to `/welcome`, showing the supplied
`assets/images/welcome-background.png` image as a full-screen background with one horizontal
black “Tiếp” button at the bottom. The button opens `/login`; registration is
accessible from Login, and Back returns to welcome.
[Welcome preview](docs/screenshots/welcome-image-continue.png).
Login, registration and password recovery use `AuthScaffold` and `AuthTheme.light`
with white backgrounds, black Revo logos, gray inputs and black primary buttons.
Each form retains its original spacing and scrolls above the keyboard. Password
recovery uses the “Nhận mã xác thực” action.
Review captures: [Login](docs/screenshots/revo-login.png),
[registration](docs/screenshots/revo-register.png) and
[password recovery](docs/screenshots/revo-forgot-password.png).

The app bundles Montserrat under the SIL Open Font License (see
`assets/fonts/Montserrat_LICENSE.txt`). Regular, Medium, SemiBold, Bold, ExtraBold
and Regular/Bold italics come from the
[official Montserrat repository](https://github.com/JulietaUla/Montserrat/tree/master/fonts/ttf).
All application themes use this font without downloading fonts at runtime.
The bundled files include Vietnamese letters and combining marks. Buttons,
navigation, form labels and custom map labels use Montserrat; Material and Font
Awesome icons retain their icon fonts.

`assets/images/logo-revo.png` is the single source logo. `RevoLogo` crops its
transparent padding in the layout and renders it in black on authentication
cards. To regenerate native splash resources:

```bash
flutter pub get
dart run tool/generate_splash.dart
flutter run
```

The script trims transparent padding, renders the mark in black and writes its
temporary PNGs to `.dart_tool/revo_splash/`, then runs `flutter_native_splash:create`.
Android 12 padding keeps the entire logo inside the system's circular mask.
Commit the source logo, splash configuration and generated Android/iOS resources;
no duplicate source logos are kept in `assets/images/`. Stop and rebuild the app
to see native splash changes; hot reload does not update them.

Login calls `POST /auth/login` and stores the returned tokens in secure storage;
the session controller then routes to the customer, provider or admin shell by
role. Registration requires a valid phone number, a strong password and terms
consent, and creates the account through `POST /auth/register`.

The login screen's recovery link opens `/forgot-password`, an email-only form
backed by `POST /auth/password/forgot` and `POST /auth/password/reset`: the
backend emails a one-time code over SMTP, and the same screen exchanges that
code for a new password. The form supports email autofill, keyboard submission,
large text and scrolling. The registration terms and privacy links show update
notices until the policy content is available.

## Home UI

`/trang-chu` opens `lib/features/home/screens/trang_chu.dart`. The screen uses
the Moto Care logo, a greeting and member card, voucher and nearby-service cards,
a right drawer with nine service entries, and five bottom navigation actions:
Trang chủ, Xe của tôi, Hoạt động, Trạm cứu hộ, and Tin nhắn.
Both the home content and drawer scroll on smaller screens and support large text.

To preview the home screen directly on a device:

```bash
flutter run --route=/trang-chu
```

Supply a `HomeUser` through Go Router's `extra` after successful authentication
to show the account's display name, member ID, and membership label. Without
account data, the greeting uses `bạn` and the member ID uses a dash.
`TrangChu.onDestinationSelected` dispatches menu, search, and navigation actions
for future feature routes; the default behavior shows availability feedback.
