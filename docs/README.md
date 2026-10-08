# Moto Care documentation

This folder is the single source of truth for technical guides, collaboration rules, and coding-agent instructions. It must be present on `main`, `cam-thu`, `thanh-vy`, and every task branch created from them.

## Read by role

| Role | Read before starting work |
| --- | --- |
| Coding agent | [AI guide](AI_GUIDE.md), [workflow](WORKFLOW.md), then the matching contributor guide |
| Cam Thu | [contribution guide](CONTRIBUTING.md) and [Cam Thu guide](branches/cam-thu.md) |
| Thanh Vy | [contribution guide](CONTRIBUTING.md) and [Thanh Vy guide](branches/thanh-vy.md) |
| Repository owner | [workflow](WORKFLOW.md) and [Android releases](RELEASES.md) |

## Contents

- [`AI_GUIDE.md`](AI_GUIDE.md): mandatory rules for coding agents.
- [`CONTRIBUTING.md`](CONTRIBUTING.md): branches, commits, and pull requests.
- [`DEPENDENCIES.md`](DEPENDENCIES.md): approved dependencies and usage boundaries.
- [`WORKFLOW.md`](WORKFLOW.md): branch protection, CI/CD, and versioning.
- [`UI_INTEGRATION_GUARDRAILS.md`](UI_INTEGRATION_GUARDRAILS.md): safe Flutter UI handoff and integration checklist.
- [`FLUTTER_INTEGRATION_FOUNDATION.md`](FLUTTER_INTEGRATION_FOUNDATION.md): shared API, session, routing, and SePay Test mode client foundation.
- [`FLUTTER_REALTIME_FOUNDATION.md`](FLUTTER_REALTIME_FOUNDATION.md): authenticated Socket.IO lifecycle, typed events, private room scopes, and REST resync rules.
- [`RELEASES.md`](RELEASES.md): Android release procedure.
- [`branches/cam-thu.md`](branches/cam-thu.md): Cam Thu's branch guide.
- [`branches/thanh-vy.md`](branches/thanh-vy.md): Thanh Vy's branch guide.
