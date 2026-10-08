# Profile module

`/tai-khoan` opens the light `ProfileScreen` from the five-tab navigation. Its
centered avatar, name, phone, static 5.0 rating presentation and Club card follow
the supplied Be reference. Name, phone, tier, points and avatar watch the shared
`profileProvider`; missing identity stays neutral. The menu is divided into
vehicle/emergency, partner/shop, and system/help groups.

The edit action opens `/thong-tin-ca-nhan` (`ThongTinCaNhanScreen`), which retains
its detailed profile and security functions. The Account menu also opens this route. Optional `HomeUser` route data supplies name, member ID,
tier and points; existing full profile data takes priority. Returning updates
both the Home greeting and Account header.

Account menu links reuse the garage, partner, voucher, FAQ and commitment routes.
The spending sheet totals completed orders only, using derived order prices.
The contact sheet shows the stored emergency contact and opens profile settings
for protected editing. Payment, shop registration and insurance sheets disclose
their currently available functions; they do not create payment methods, submit
shop applications or sell insurance. The settings sheet links to profile security,
service terms and FAQ. `test/be_screens_test.dart` covers these new interactions
and reactive data, plus 320px layouts with 1.5x text.

The detailed edit screen uses the shared light background, white cards, orange
account controls and five-tab bottom navigation with Account selected. Its scroll view and modal edit sheet support narrow screens,
larger text and the keyboard.

[Personal information preview](screenshots/light-personal-info.png).

## Data and session state

- `UserProfile` holds account and emergency contact fields. `ProfileVehicle` holds vehicle type, plate and tire type. Additional `medicalNote` and `workAddress` fields supply the requested UI sections. Both models support JSON conversion.
- `profileProvider` owns the immutable profile, selected avatar bytes and biometric preference through Riverpod. `initialUserProfileProvider` can supply full account data or be overridden in tests. Reopening the same profile keeps edits; changing member ID clears the previous profile's session data.
- The edit sheet validates the name and Vietnamese mobile/landline numbers, accepts formatted `+84` numbers and normalizes them to a `0` prefix. The emergency phone and medical note are optional. Canceling the sheet keeps the original data.
- All edits and preferences currently live in memory. They reset after logout or app restart. No profile, medical notes or credentials are written to disk, logs or the repository.

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
