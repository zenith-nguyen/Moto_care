# Profile module

`/tai-khoan` opens the stateful customer dashboard at
`lib/features/customer/profile/profile_screen.dart`; the former profile screen
path re-exports it to preserve existing imports and routes. The MoMo-inspired
layout uses a pale-blue-to-white header, a white profile card, four quick actions,
a 2x2 vehicle/address utility grid, partner links, and grouped security/support
rows. Its scoped theme uses white, black and the shared navigation blue
`#3478D4`, with `#EAF1FC` accent surfaces. Avatar controls, shortcut icons,
utility icons and actions use this palette. The active Account tab uses the
same icon, label and background colors as Activity through `HomeBottomNavigation`.

Name, phone and avatar watch the shared `profileProvider`; missing identity stays
neutral. The existing static 5.0 rating presentation is retained. A green
verification tick appears only when `UserProfile.isVerified` is supplied as true;
the default is false. Reference names and phone numbers do not replace account
data. The dashboard has no membership badge, and the detailed profile suppresses
the unranked badge. Club and reward features remain removed.

The edit action opens `/thong-tin-ca-nhan` (`ThongTinCaNhanScreen`), which retains
its detailed profile and security functions. The Account menu also opens this route. Optional `HomeUser` route data supplies name and account ID;
existing full profile data takes priority. Returning updates
both the Home greeting and Account header.

Account menu links reuse the garage, partner, FAQ and commitment routes.
The spending sheet totals completed orders only, using derived order prices.
The contact sheet shows the stored emergency contact and opens profile settings
for protected editing. Vehicle information and saved-address tiles show the
stored profile values; vehicle management still opens the garage. The email row
shows the linked email. Payment, shop registration and insurance sheets disclose
their currently available functions; they do not create payment methods, submit
shop applications or sell insurance. The settings sheet links to profile security,
service terms and FAQ. Password changes, biometric preferences, logout and
account deletion are available directly from the dashboard. Its
`profileActionsProvider` coordinates pending device/account operations, prevents
duplicate requests and ignores avatar results after the account changes. The
presentation adapter owns confirmations and navigation. Existing detail-screen
security checks and service error handling remain available.

`test/profile_dashboard_test.dart` and `test/be_screens_test.dart` cover the
dashboard actions, reactive data, protected operations, cancellation/failure,
session cleanup and 320px layouts with 1.5x text.

The detailed edit screen uses the shared light background, white cards, orange
account controls and four-tab bottom navigation with Account selected. Its scroll view and modal edit sheet support narrow screens,
larger text and the keyboard.

[Blue dashboard preview](screenshots/profile-dashboard-blue.png),
[earlier dashboard preview](screenshots/profile-dashboard.png),
[utilities and security](screenshots/profile-dashboard-utilities.png), and
[support and session actions](screenshots/profile-dashboard-settings.png).

[Personal information preview](screenshots/light-personal-info.png).

## Data and session state

- `UserProfile` holds account and emergency contact fields. `ProfileVehicle` holds vehicle type, plate and tire type. Additional `medicalNote` and `workAddress` fields supply the requested UI sections. Both models support JSON conversion.
- `profileProvider` owns the immutable profile, selected avatar bytes and biometric preference through Riverpod. `initialUserProfileProvider` can supply full account data or be overridden in tests. Reopening the same profile keeps edits; changing member ID clears the previous profile's session data.
- The edit sheet validates the name and Vietnamese mobile/landline numbers, accepts formatted `+84` numbers and normalizes them to a `0` prefix. The emergency phone and medical note are optional. Canceling the sheet keeps the original data.
- In the live application, name, phone, emergency contact, medical note, home
  address and work address are loaded from and saved to authenticated
  `GET/PATCH /users/me`; PostgreSQL is the source of truth across app restarts.
  Widget tests keep an in-memory repository so they remain deterministic.
  Avatar bytes and the biometric preference are still device/session-only and
  are not uploaded by this profile endpoint. Passwords and tokens are never
  stored in profile state or logs.

## Device features

`ProfileDeviceService` is injected through Riverpod and mocked by widget tests. Its native implementation selects a gallery image, caps its dimensions and checks a 5 MB limit. `Image.memory` displays local selections; `avatarUrl` displays API-provided images with an error fallback. Android lost-picker data is recovered when the profile opens.

Enabling FaceID / fingerprint requires successful device biometric authentication. When enabled, editing details, changing the avatar, changing the password, deleting the account or disabling the option also requires authentication. Canceled, failed or unsupported authentication keeps the previous setting and data. This preference protects profile actions during the current session; it does not add a biometric login or app-wide lock.

Native configuration follows the Flutter team's [image_picker documentation](https://pub.dev/packages/image_picker), [local_auth Android setup](https://pub.dev/packages/local_auth_android) and [local_auth Darwin setup](https://pub.dev/packages/local_auth_darwin):

- Android: `FlutterFragmentActivity`, `USE_BIOMETRIC`, AppCompat launch/normal themes, and `INTERNET` for remote avatars.
- iOS: photo-library and Face ID usage descriptions. This feature uses the gallery, so camera or microphone access is not requested.
- macOS: read access to user-selected files for the gallery picker.

Run a full app restart/rebuild after adding the plugins. Verify gallery selection and biometrics on a real supported device; Flutter widget tests cannot exercise native OS dialogs.

## Account service boundary

`ProfileAccountService` defines asynchronous `changePassword` and `deleteAccount` operations. The current default throws a clear unavailable-service error because this project has no account backend. The UI never reports success or removes profile data on a failed operation. Replace this service through its provider with an implementation using the centralized Dio client once the endpoints exist.

The password dialog validates the current/new/confirmation fields, prevents duplicate submissions and disposes its controllers. Passwords stay inside the dialog and are never stored in profile state. Account deletion requires a confirmation and only clears the session after the service succeeds. Logout clears local profile state and replaces the route stack with `/login`; it currently does not revoke a server session because authentication is a development bypass.
