# Dependency guide

This document defines the approved baseline dependencies for Moto Care. Add a package only when its responsibility is needed by the current task. Do not introduce a competing package in the same category without a repository-owner decision.

## Project identity

- Flutter package name: `moto_care`
- Android application ID and Apple bundle ID: `com.motocare.app`
- User-facing application name: `Moto Care`

Treat the application and bundle IDs as permanent after the first store release. Changing them later creates a different application identity for users and stores.

| Package | Responsibility | Use when |
| --- | --- | --- |
| `flutter_riverpod` | Application state and dependency injection | A screen needs shared, asynchronous, or testable state. |
| `go_router` | Navigation, deep links, and auth redirects | The application has more than one screen or an authentication flow. |
| `url_launcher` | Open system applications through URL schemes | Opening the phone app with a `tel:` URI or a map through a Google Maps URL from rescue features. |
| `image_picker` | Select images from the device photo library | Changing the profile avatar; keep local bytes in session state until an upload API exists. |
| `local_auth` | Device biometric authentication | Verifying Face ID / fingerprint before editing profile information when the option is enabled. |
| `font_awesome_flutter` | Font Awesome icons | Displaying icons, including password visibility controls. |
| `flutter_native_splash` | Generate native Android and iOS splash screens (development only). | Regenerating launch resources after a logo or splash configuration change. |
| `image` | Crop the source JPG (or PNG when JPG is absent) and export splash PNGs (development only). | Running `dart run tool/generate_splash.dart`. |
| `intl` and `flutter_localizations` | Locale-aware dates, currency, and translated UI | Presenting dates, VND amounts, or more than one language. |
| `dio` | HTTP client | Calling the Moto Care backend. Configure timeouts and interceptors in one client. |
| `flutter_secure_storage` | Encrypted device storage | Persisting credentials, access tokens, or refresh tokens. Never use it for non-sensitive UI preferences. |
| `json_annotation` | Model annotations | Defining API request and response models. |
| `build_runner` and `json_serializable` | JSON model code generation | Generating `fromJson` and `toJson` for annotated models. |

## Boundaries

- Use only `flutter_riverpod` for new application state. Do not add `provider`, `bloc`, or another state-management library without an explicit architecture decision.
- Use only `go_router` for new app-level routes. Do not mix it with a second routing framework.
- Use `dio` for backend communication. Keep base URL, headers, token injection, retries, and error mapping in the data layer rather than in widgets.
- Store tokens only with `flutter_secure_storage`. Do not place them in source code, logs, `shared_preferences`, or version control.
- Run `dart run build_runner build --delete-conflicting-outputs` after changing a `json_serializable` model, then commit the generated `.g.dart` file with its source model.
- Add feature-specific plugins, such as location, maps, camera, notifications, or image picking, only when the associated feature is approved.
