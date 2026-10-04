# MotoCare Backend

NestJS API for the MotoCare motorbike roadside-assistance application. The Flutter mobile app is in the repository root; this directory contains the backend.

## Local development

1. Copy `.env.example` to `.env` and replace `JWT_SECRET` with a unique value of at least 32 characters.
2. Install packages: `npm ci`.
3. Start Postgres with PostGIS: `docker compose up -d`.
4. Apply migrations: `npm run migration:run`.
5. Seed local development data: `npm run seed`.
6. Start the API: `npm run start:dev`.

The API is available at `http://localhost:3000`, its health probe at `/health`, and Swagger UI at `/docs`.

The `/docs` page only responds while the NestJS process is running. Use its **Authorize** button with an access token from `POST /auth/login` to try protected endpoints.

## Orders and provider availability

The provider app calls `PATCH /providers/me/location` with `{ "latitude": 10.7769, "longitude": 106.7009 }` every 30–60 seconds while online, including when it has no order. It then calls `PATCH /providers/me/status` with `{ "isOnline": true }` to accept offers. Only an approved, active provider with a location updated in the last 120 seconds can go online. Matching also checks that freshness, approval, account status, current offers, and active orders. Seeded providers start online, but their location becomes stale after 120 seconds; update their location before testing matching later.

Customers use `GET /incident-types` to display selectable incidents and `POST /orders` with the following body:

```json
{
  "incident_type_id": 1,
  "customer_location": { "latitude": 10.7769, "longitude": 106.7009 }
}
```

The order snapshots the current `base_price`. A provider receives one offer for 15 seconds. If they reject or the offer expires, matching tries the next nearest provider. If none is available, the order stays `PENDING_MATCH`; the customer can call `POST /orders/:id/retry-match` later. Customers and related providers can poll `GET /orders/:id`. Providers can poll `GET /providers/me/offers/pending` for their own active offers and call `POST /orders/:id/offers/:offerId/accept` or `/reject`. Swagger documents all request and response bodies. Money is returned as decimal strings; PostGIS coordinates are stored as `[longitude, latitude]`.

`MATCH_RADIUS_KM` (default 10), `OFFER_TTL_SECONDS` (default 15), and `PROVIDER_LOCATION_MAX_AGE_SECONDS` (default 120) can be set in `.env`. The expiry job runs every five seconds through `@nestjs/schedule`. PostgreSQL row locks and unique indexes prevent simultaneous duplicate offers and accepts.

New provider registration also creates a `providers` profile with `PENDING` approval and offline status. Only the seed supplies approved providers for local tests until Admin approval APIs are implemented.

## Quality checks

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

After the test database exists, only the last three commands are needed for another run. The test suite covers matching order, exclusions, offer expiry, provider presence, and concurrent accepts on real PostgreSQL/PostGIS.

The GitHub Actions workflow runs these checks for pull requests and updates to `main` or `feat/**` branches. Changes must be proposed through a PR using Conventional Commits.

## Database

Local development uses `postgis/postgis:16-3.4`. TypeORM always uses migrations; `synchronize` is disabled.

Run the database setup from this directory:

```powershell
docker compose up -d
npm run migration:run
npm run seed
```

The migration sequence enables PostGIS, creates `users`, creates the core schema, and adds partial unique indexes that prevent multiple pending offers for one order or provider and multiple active orders for one provider.

The seed creates five selectable incident types, three approved online providers around Ho Chi Minh City, one development customer, one development admin, and a wallet for each seeded provider. All seeded accounts use the development-only password `MotoCareDev123!`; never reuse it outside local development.

To verify the PostGIS nearest-provider query:

```powershell
npm run db:check-nearest-provider
```

The check filters approved online providers with `ST_DWithin` and verifies that the result is sorted by `ST_Distance`.

All price and wallet columns use PostgreSQL `numeric`/`decimal`, never floating-point types. Location columns use `geography(Point, 4326)` with GiST indexes.
