# Revo documentation

This folder is the single source of truth for technical guides, collaboration rules, and coding-agent instructions. It must be present on `main`, `cam-thu`, `thanh-vy`, and every task branch created from them.

## Read by role

| Role | Read before starting work |
| --- | --- |
| Coding agent | [AI guide](AI_GUIDE.md), [workflow](WORKFLOW.md), then the matching contributor guide |
| Cam Thu | [contribution guide](CONTRIBUTING.md) and [Cam Thu guide](branches/cam-thu.md) |
| Thanh Vy | [contribution guide](CONTRIBUTING.md) and [Thanh Vy guide](branches/thanh-vy.md) |
| Repository owner | [workflow](WORKFLOW.md) and [Android releases](RELEASES.md) |

## Contents

- [`ADMIN.md`](ADMIN.md): Admin sandbox, role integration, dashboard, approvals, requests and reconciliation.
- [`ARCHITECTURE.md`](ARCHITECTURE.md): feature boundaries, data flow, injected services, route drafts and UI-preserving refactor.

- [`MARKETPLACE.md`](MARKETPLACE.md): partner discovery, package cart, GPS, checkout and rescue tracking.
- [`ORDER_TRACKING.md`](ORDER_TRACKING.md): order status, map markers, simulated mechanic movement, contacts and cancellation.
- [`ORDER_DETAILS.md`](ORDER_DETAILS.md): rescue progress details, timeline events, requester snapshots and map/contact navigation.
- [`SERVICE_RATING.md`](SERVICE_RATING.md): service/mechanic rating, quick tags, comments, photos, Home navigation and review session storage.
- [`STATION_DETAILS.md`](STATION_DETAILS.md): station gallery, profile, services, favorites, sharing, reviews, chat and booking navigation.
- [`HOME.md`](HOME.md): Revo station grid, search/filtering, emergency selection, navigation and session boundaries.
- [`HOME_ASSETS.md`](HOME_ASSETS.md): generated station illustration paths and final prompts.
- [`LOCATION.md`](LOCATION.md): Places autocomplete, geocoding, Google Maps confirmation and rescue request details.
- [`VEHICLES_AND_RESCUE_STATIONS.md`](VEHICLES_AND_RESCUE_STATIONS.md): vehicle management, station discovery, native actions and bottom tab routing.
- [`SERVICE_SCREENS.md`](SERVICE_SCREENS.md): places, pricing, partner forms, policies, FAQ and emergency tips.
- [`ACTIVITY.md`](ACTIVITY.md): Activity module models, routes, state and demo boundaries.
- [`PROFILE.md`](PROFILE.md): Profile models, editing, account services and native plugin configuration.
- [`CHAT.md`](CHAT.md): monochrome conversation layout, contacts, quick replies, attachments and keyboard behavior.
- [`AI_GUIDE.md`](AI_GUIDE.md): mandatory rules for coding agents.
- [`CONTRIBUTING.md`](CONTRIBUTING.md): branches, commits, and pull requests.
- [`DEPENDENCIES.md`](DEPENDENCIES.md): approved dependencies and usage boundaries.
- [`WORKFLOW.md`](WORKFLOW.md): branch protection, CI/CD, and versioning.
- [`RELEASES.md`](RELEASES.md): Android release procedure.
- [`branches/cam-thu.md`](branches/cam-thu.md): Cam Thu's branch guide.
- [`branches/thanh-vy.md`](branches/thanh-vy.md): Thanh Vy's branch guide.
