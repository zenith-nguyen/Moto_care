# PR #22 Customer UI review

Review date: 2026-10-11  
Reviewed head commit: `1e55e8c` (`feat/cam-thu/be-light-screens`)

## Decision

Do **not** merge PR #22 directly into `main` in its current form.

The pull request contains useful Customer screens and assets, but GitHub reports
merge conflicts and the branch was created before the current backend and
Flutter integration foundation. Its full tree would remove or replace current
backend, CI, documentation, routing, API repositories, session, and realtime
work. The pull request also has no CI result for the current repository rules.

The branch name follows Cam Thu's namespace, but its first integration target
must be `cam-thu`, not `main`. The role branch must first be synchronized with
the latest `main`.

## Safe integration plan

1. Update `cam-thu` from the latest `main` without changing branch protection or
   CI rules.
2. Create a fresh `feat/cam-thu/customer-ui-integration` branch from the updated
   `cam-thu` branch.
3. Port UI in small slices instead of merging the old project tree:
   - shared theme, intentional assets, and reusable widgets;
   - authentication and Customer profile screens;
   - Customer home, incident selection, and order creation;
   - vehicle management;
   - order tracking, provider contact, GPS, and chat;
   - nearby repair/fuel/charging/parts markers;
   - optional marketplace presentation only after its API contract exists.
4. Connect each slice to the repositories/controllers already present on
   `main`. Runtime mock data must not remain the source of truth.
5. Open the first PR into `cam-thu`. After that branch is tested and synchronized,
   open the role integration PR from `cam-thu` into `main`.

## Preserve from current main

Do not overwrite or delete:

- `backend/`, `.github/`, `AGENTS.md`, `CONTRIBUTING.md`, or repository docs;
- the shared Dio client, secure session, role routing, and REST repositories;
- the Socket.IO session and its REST resynchronization behavior;
- existing platform configuration or `pubspec.yaml` as a whole.

Dependencies should be added one at a time and only when an imported screen uses
them. Google Maps must not become mandatory for the no-cost demo. The current
service-location backend is provider-neutral and works with any Flutter map
renderer.

## Remove from the integration diff

- `.vscode/`;
- numbered copies of `.flutter-plugins-dependencies`;
- generated iOS environment files;
- build/cache output and temporary screenshots;
- old backend, workflow, governance, or project metadata copied from the
  standalone prototype;
- hard-coded users, orders, repair shops, chat messages, GPS points, and other
  runtime mock data once the corresponding repository is connected.

The reviewed map configuration contains placeholder values only; no usable map
key was detected. API keys, JWTs, passwords, webhook secrets, SMTP credentials,
and bank information must never be added to the Flutter project.

## Verification status

- `dart format --output=none --set-exit-if-changed lib test`: passed for the PR
  worktree (203 files, no formatting changes).
- `flutter pub get` / analyze / test / APK build: not verified on this Windows
  machine because Flutter plugin symlinks require Windows Developer Mode.
- GitHub mergeability: conflicting.
- GitHub CI: no current checks attached to the PR.

Passing format alone is not approval to merge. The fresh integration branch must
pass the full checklist in [UI_INTEGRATION_GUARDRAILS.md](UI_INTEGRATION_GUARDRAILS.md).
