# AI coding guide

This guide is mandatory for every coding agent before it proposes or changes Moto Care source code. Read [the workflow](WORKFLOW.md), [dependency guide](DEPENDENCIES.md), and the relevant contributor guide before starting.

## Mandatory rules

1. Never commit or push directly to `main`, `cam-thu`, or `thanh-vy`. Create a task branch and open a pull request into the appropriate integration branch. The repository owner uses `feat|fix|docs|refactor|test|chore/zenith/<description>` for direct PRs into `main`; the dedicated `feat/db-schema` branch is allowed for the database-schema milestone.
2. Change only what the request needs. Do not make bulk formatting changes, upgrade dependencies, or edit platform files unless the task requires it.
3. Never commit API keys, passwords, keystores, `.env` files, or user data. Store CI/CD secrets in GitHub Secrets.
4. Keep Dart formatting, `flutter analyze`, `flutter test`, and Android builds passing. Do not disable tests or lints merely to make a check pass.
5. Update tests when behavior changes. Update documentation when changing process, architecture, configuration, or release behavior.
6. Keep `pubspec.lock` in sync when changing dependencies. Change `version:` only for a release prepared on `main`.

## Change conventions

- Use idiomatic Dart and Flutter names and structure. Prefer small widgets with one clear responsibility.
- Do not mix unrelated UI, business-logic, and dependency changes in one pull request.
- Use Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, or `chore:`.
- A pull request describes its goal and validation. Include screenshots for UI changes.
- When context is missing, make only the smallest safe change and state assumptions in the pull request description.
