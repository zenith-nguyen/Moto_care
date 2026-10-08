# Flutter UI integration guardrails

Use this checklist when moving Customer, Provider, or Admin UI into the shared
application. UI pull requests must preserve the backend, repository governance,
supported Flutter platforms, and the existing API integration foundation.

## Branch flow

- Cam Thu creates `feat/cam-thu/<topic>` from `cam-thu` and opens the first PR
  into `cam-thu`.
- Thanh Vy creates `feat/thanh-vy/<topic>` from `thanh-vy` and opens the first
  PR into `thanh-vy`.
- Only the synchronized `cam-thu` or `thanh-vy` branch opens a PR into `main`.
- Owner integration work uses `(feat|fix|docs|refactor|test|chore)/zenith/<topic>`
  from the current `main`.

Do not weaken `.github/workflows/pr-policy.yml` to make a branch pass. Fix the
branch flow instead.

## Files that UI work must preserve

- `.github/`, `AGENTS.md`, `CONTRIBUTING.md`, `docs/`, and `backend/`.
- Existing Android, iOS, macOS, web, and Windows project files unless the PR
  documents a necessary platform-specific change.
- Existing Dio, Riverpod, GoRouter, secure-storage, JSON, localization, and test
  dependencies. Add a package only when a screen actually uses it.
- Existing API contracts in `backend/docs/FLUTTER_API_HANDOFF.md` and
  `backend/docs/UI_WORKFLOW_CONTRACT.md`.

Never replace the complete `pubspec.yaml`, router, or application state with an
older standalone prototype. Adapt screens into the shared structure in small
commits.

## Files that must stay local

Do not commit editor state, Flutter package metadata, build output, Kotlin
daemon state, or generated iOS environment files. In particular:

- `.vscode/`
- `.flutter-plugins-dependencies` and numbered copies
- `.dart_tool/`, `build/`, and `coverage/`
- `android/.kotlin/`
- `ios/Flutter/Generated.xcconfig`
- `ios/Flutter/flutter_export_environment.sh`

The Flutter CI job rejects these paths even if a local ignore rule is bypassed.

## Secrets, maps, and demo mode

- Do not commit API keys, JWTs, passwords, webhook secrets, SMTP credentials,
  bank details, or a populated `.env` file.
- Google Maps must not be required for the no-cost demo. A screen that supports
  Google Maps must also run without a key by using the approved mock or
  no-billing fallback.
- Flutter receives only the public API base URL and public feature flags. DB,
  JWT signing, reset-code, and SePay webhook secrets stay on the backend.
- Demo/Test payment UI must visibly show that it is simulation-only and must not
  claim that real money was transferred or refunded.

## Integration order

1. Start from the latest `main` and import one role at a time.
2. Import reusable theme/widgets/models before complete screens.
3. Connect REST snapshots and error/loading states before Socket.IO updates.
4. Add realtime offer/order/GPS/chat events with REST resynchronization after
   reconnect.
5. Add assets deliberately; avoid screenshots and temporary design exports.
6. Run the full acceptance commands and review the final diff before opening a
   PR.

## Acceptance commands

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug

cd backend
npm ci
npm run typecheck
npm run lint
npm test -- --runInBand
npm run build
```

If a UI-only PR changes or deletes backend/governance files, stop and split the
PR before review. Do not merge first and repair `main` afterward.
