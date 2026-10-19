# Revo

Revo is a mobile roadside-assistance application for motorbike riders. It connects customers who need help with nearby approved mobile mechanics.

This repository contains the Flutter mobile application. The NestJS, PostgreSQL/PostGIS, WebSocket, payment, and administration services live in a separate backend repository.

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

The project is a one-month mobile-development course project. Its required final deliverable is an Android APK.

## Documentation

Project guides, contribution rules, AI instructions, CI/CD, and release procedures are maintained in [`docs/`](docs/README.md).

## Run locally

```bash
flutter pub get
flutter run
```

## Startup and authentication UI

Android and iOS show a white native splash screen with Revo branding. Once
Flutter is ready, `/` redirects to `/welcome`, showing the supplied
`assets/images/Ảnh.png` image as a full-screen background with one horizontal
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

`assets/images/REVO.png` is the single source logo. `RevoLogo` crops its
transparent padding in the layout and renders it in black on authentication
cards. The wider wordmark remains centered within the existing header space.
To regenerate native splash resources:

```bash
flutter pub get
dart run tool/generate_splash.dart
flutter run
```

The script trims transparent padding, renders the mark in black and writes its
temporary PNGs to `.dart_tool/revo_splash/`, then runs `flutter_native_splash:create`.
Android 12 padding keeps the entire logo inside the system's circular mask.
Commit the source logo, splash configuration and generated Android/iOS resources;
only `REVO.png` is bundled as the application logo. Stop and rebuild the app
to see native splash changes; hot reload does not update them.

The login screen has a temporary DEV bypass: pressing `Đăng nhập` opens home
without validating credentials. Registration requires a valid phone number, a strong password and terms
consent; submitting currently shows an availability notice.

The login screen's recovery link opens `/forgot-password`, an email-only form.
It supports email autofill, keyboard submission, large text and scrolling, but does
not send email or claim that a code has been sent. Its email recovery API and
account email association need to be provided by the backend before release.
The registration terms and
privacy links show update notices until the policy content is available.

## Home UI

`/trang-chu` opens `lib/features/home/screens/trang_chu.dart`. The screen uses
the Revo logo, a greeting and member card, voucher and nearby-service cards,
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
