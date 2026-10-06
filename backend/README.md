# MotoCare Backend

NestJS API for the MotoCare motorbike roadside-assistance application. The Flutter mobile app is in the repository root; this directory contains the backend.

## Local development

1. Copy `.env.example` to `.env` and replace `JWT_SECRET` with a unique value of at least 32 characters.
2. Install packages: `npm ci`.
3. Start Postgres with PostGIS: `docker compose up -d`.
4. Apply migrations: `npm run migration:run`.
5. Seed local development data: `npm run seed`.
6. Start the API: `npm run start:dev`.

The API is available at `http://localhost:3000`; `/health` checks the Nest process and `/health/ready` additionally checks PostgreSQL. Swagger UI is at `/docs` in local development.

The `/docs` page is available only when NestJS is running with `DEMO_MODE=false` and outside production. It is disabled in public demo mode; use its **Authorize** button with an access token from `POST /auth/login` to try protected endpoints during local development.

## Security baseline

Every response includes `X-Request-ID`; API errors use a consistent safe body and never expose stack traces or SQL. Access logs exclude query strings, request bodies and authorization data. Helmet security headers, strict CORS and global REST throttling are enabled. Auth and chat-upload endpoints have tighter limits.

Run `npm run security:check-files` before pushing. It rejects tracked environment files, private keys, keystores, runtime uploads and several common token formats without printing the secret value. For public/production use, configure separate random `JWT_SECRET`, `ORDER_START_HMAC_SECRET` and `PASSWORD_RESET_HMAC_SECRET`; local development may fall back to `JWT_SECRET` for the two HMAC uses. See [SECURITY.md](docs/SECURITY.md). Never put any of these values in Flutter or a `--dart-define`.

## Password recovery

`POST /auth/password/forgot` accepts an email and always returns a generic response. For registered email accounts, it creates a six-digit, one-time code that expires after 10 minutes. `POST /auth/password/reset` accepts the email, code and a new password. A successful reset invalidates all JWTs issued before it. Five consecutive failed login attempts temporarily lock the account for 15 minutes.

Email delivery is disabled by default. To test with a dedicated Gmail demo account, enable two-step verification, create an App Password and set `EMAIL_ENABLED=true`, `SMTP_HOST=smtp.gmail.com`, `SMTP_PORT=587`, `SMTP_SECURE=false`, `SMTP_USER`, `SMTP_PASSWORD` and `SMTP_FROM` in the untracked `.env`. Never paste the App Password into chat, screenshots or committed files. Accounts registered only by phone cannot use email recovery. See [AUTH_SECURITY.md](docs/AUTH_SECURITY.md) for the complete flow and Flutter contract.

## Orders and provider availability

The provider app calls `PATCH /providers/me/location` with `{ "latitude": 10.7769, "longitude": 106.7009 }` every 30–60 seconds while online, including when it has no order. It then calls `PATCH /providers/me/status` with `{ "isOnline": true }` to accept offers. Only an approved, active provider with a location updated in the last 120 seconds can go online. Matching also checks that freshness, approval, account status, current offers, and active orders. Seeded providers start online, but their location becomes stale after 120 seconds; update their location before testing matching later.

Customers use `GET /incident-types` to display selectable incidents and `POST /orders` with the following body:

```json
{
  "incident_type_id": 1,
  "customer_location": { "latitude": 10.7769, "longitude": 106.7009 }
}
```

The order snapshots the incident base price and optional weather surcharge, then starts in `AWAITING_PREPAYMENT`. `WEATHER_PRICING_ENABLED=false` is the safe default. When enabled for the non-commercial educational demo, the backend queries Open-Meteo at rounded customer coordinates, caches the result, applies `1.00`/`1.10`/`1.20`, and falls back to `1.00` on timeout or invalid data. The response `pricing` object contains the immutable breakdown and attribution. See [WEATHER_PRICING_PLAN.md](docs/WEATHER_PRICING_PLAN.md).

No offer is sent until payment is confirmed. For **local sandbox only**, set `DEMO_MODE=true` and call `POST /payments/demo/orders/:id/confirm` as the customer to simulate exact payment (no bank transfer). Matching then offers one provider 15 seconds. If they reject or time out, matching tries the next nearest provider. If none is available, the order stays `PENDING_MATCH`; the customer can call `POST /orders/:id/retry-match` later. Customers and related providers can poll `GET /orders/:id`. Providers can poll `GET /providers/me/offers/pending` for their own active offers and call `POST /orders/:id/offers/:offerId/accept` or `/reject`. Swagger documents all request and response bodies. Money is returned as decimal strings; PostGIS coordinates are stored as `[longitude, latitude]`.

`MATCH_RADIUS_KM` (default 10), `OFFER_TTL_SECONDS` (default 15), and `PROVIDER_LOCATION_MAX_AGE_SECONDS` (default 120) can be set in `.env`. The expiry job runs every five seconds through `@nestjs/schedule`. PostgreSQL row locks and unique indexes prevent simultaneous duplicate offers and accepts.

New provider registration also creates a `providers` profile with `PENDING` approval and offline status. Admin can use `GET /admin/providers/pending` and `PATCH /admin/providers/:id/approval` to review it. After approval, the provider updates GPS then goes online. A provider on an active order calls `PATCH /providers/me/orders/:id/location` every few seconds; the customer can poll `GET /orders/:id` or subscribe to Socket.IO. Chat history and sending are available at `GET/POST /orders/:id/messages` for order participants only. The POST accepts text JSON or multipart text/image (JPEG, PNG, WebP; one image up to 5 MiB). Images are not public static files; load the protected URL in the response with the same Bearer token. See [CHAT_WORKFLOW.md](docs/CHAT_WORKFLOW.md).

Customers may call `POST /orders/:id/cancel` before work starts. An unpaid order becomes `CANCELLED`; a paid order becomes `REFUND_PENDING`. An admin can call `POST /payments/demo/orders/:id/refund` to simulate a **full** refund, moving it to `REFUNDED`. Neither action moves real money. Cancellation after work starts is blocked pending an admin-dispute workflow. No bank QR, SePay webhook, payout or partial-refund logic is implemented yet. **Never use the demo confirmation/refund endpoints as proof of real payment.** Demo payment is disabled when `NODE_ENV=production`, even if `DEMO_MODE=true`.

For a successful demo order, the assigned provider calls `POST /orders/:id/arrive`. The customer fetches `GET /orders/:id/start-token` and presents its five-minute HMAC token as text/QR; the provider sends it to `POST /orders/:id/start`. The provider then proposes a final price. The customer approves or rejects it; rejected proposals can be escalated to Admin. A higher price creates a sandbox charge adjustment and a lower price creates a sandbox refund adjustment. Only after that adjustment is settled may the provider call `/complete`, which reconciles the ledger and credits the provider wallet exactly once. `GET /wallets/me` remains demo-only and not withdrawable. See [FINAL_PRICE_WORKFLOW.md](docs/FINAL_PRICE_WORKFLOW.md).

Socket.IO connects at the same API origin with `auth: { token: '<JWT>', orderId: <id> }`. Providers that were already approved and online at connection time also join their provider room; reconnect after changing online status. Events: `offer.created`/`offer.expired` for providers and `order.status_changed`/`provider.location_updated`/`message.created` for order participants. On reconnect, fetch `GET /orders/:id`, `GET /providers/me/offers/pending`, and `GET /orders/:id/messages` rather than assuming no event was missed. See [API_CATALOG.md](docs/API_CATALOG.md) for the current endpoint inventory, [FLUTTER_API_HANDOFF.md](docs/FLUTTER_API_HANDOFF.md) for the Flutter contract and [DEMO_RUNBOOK.md](docs/DEMO_RUNBOOK.md) for the three-screen/teacher demo checklist.

## Quality checks

History and admin lists: `GET /orders` returns the latest 30 own orders for a customer or provider (pending offers have their own endpoint). Admin uses `GET /admin/orders` for recent orders and `GET /admin/refunds/pending` to find pending demo refunds.

Admin analytics are available through `GET /admin/dashboard/summary`, `GET /admin/dashboard/timeseries`, and `GET /admin/reconciliation`. They accept an optional ISO `from`/`to` period (seven days by default, 366 days maximum), group daily data in `Asia/Ho_Chi_Minh`, return money as decimal strings, and distinguish collected, currently held, provider-settled, pending-refund, and refunded amounts. These are sandbox accounting metrics, not proof of bank transactions or platform revenue. See [ADMIN_ANALYTICS_PLAN.md](docs/ADMIN_ANALYTICS_PLAN.md).

```bash
npm run lint
npm test
npm run build
```

The database integration suite uses a dedicated test database and truncates its application tables between tests. Do not point it at the development database. Create and migrate it once from a normal PowerShell window, in `backend/`:

```powershell
docker exec motocare-postgres createdb -U motocare motocare_orders_test
$env:DATABASE_NAME = 'motocare_orders_test'
npm run migration:run
Remove-Item Env:DATABASE_NAME
$env:TEST_DATABASE_NAME = 'motocare_orders_test'
npm run test:db
Remove-Item Env:TEST_DATABASE_NAME
```

After the test database exists, only the last three commands are needed for another run. The test suite covers matching order, exclusions, offer expiry, provider presence, concurrent accepts, and the complete three-role sandbox flow over HTTP with real JWT guards and validation. CI starts an isolated PostGIS service, runs migrations, then executes this suite.

The GitHub Actions workflow runs these checks for pull requests and updates to `main` or `feat/**` branches. Changes must be proposed through a PR using Conventional Commits.

## Demo backup and restore

Database rows and chat images are separate, so a valid demo backup must include both. With Docker running, check capacity and create a timestamped snapshot with:

```powershell
npm run backup:check
npm run backup:create
```

Snapshots are written under the ignored `backups/` directory and include a PostgreSQL custom dump, a chat-image archive and a SHA-256 manifest. They contain sensitive application data and are not encrypted. Do not commit or share them. Restore is deliberately limited to a new test/restore database; follow [BACKUP_RESTORE.md](docs/BACKUP_RESTORE.md) and rehearse before an important demo.

## Database

Local development uses `postgis/postgis:16-3.4`. TypeORM always uses migrations; `synchronize` is disabled.

Run the database setup from this directory:

```powershell
docker compose up -d
npm run migration:run
npm run seed
```

The migration sequence enables PostGIS, creates the core schema, protects matching/wallet invariants, adds chat/password recovery/weather snapshots, and adds final-price proposals plus payment-adjustment ledgers. Migrations run transactionally one at a time because a later migration expands a partial index with newly committed PostgreSQL enum values. Enum additions cannot be automatically removed; take a backup before applying them to any important database.

The seed creates five selectable incident types, three approved online providers around Ho Chi Minh City, one development customer, one development admin, and a wallet for each seeded provider. By default all seeded accounts use the development-only password `MotoCareDev123!`; **never run this default seed against a publicly accessible or production database**. The script rejects `NODE_ENV=production`. For a separate demo database set `DEMO_MODE=true` and distinct `SEED_CUSTOMER_PASSWORD`, `SEED_PROVIDER_PASSWORD`, `SEED_ADMIN_PASSWORD` (each 16+ characters) before `npm run seed`. Existing users' passwords are not changed by reseeding. Never expose a database containing default-password accounts.

To verify the PostGIS nearest-provider query:

```powershell
npm run db:check-nearest-provider
```

The check filters approved online providers with `ST_DWithin` and verifies that the result is sorted by `ST_Distance`.

All price and wallet columns use PostgreSQL `numeric`/`decimal`, never floating-point types. Location columns use `geography(Point, 4326)` with GiST indexes.
