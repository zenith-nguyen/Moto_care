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

## Quality checks

```bash
npm run lint
npm test
npm run build
```

The GitHub Actions workflow runs these checks for pull requests and updates to `main` or `feat/**` branches. Changes must be proposed through a PR using Conventional Commits.

## Database

Local development uses `postgis/postgis:16-3.4`. TypeORM always uses migrations; `synchronize` is disabled.

Run the database setup from this directory:

```powershell
docker compose up -d
npm run migration:run
npm run seed
```

The migration sequence enables PostGIS, creates `users`, and then creates the core schema: providers, incident types, orders, offers, messages, reviews, payments, wallets, wallet transactions, and withdrawal requests.

The seed creates five selectable incident types, three approved online providers around Ho Chi Minh City, one development customer, one development admin, and a wallet for each seeded provider. All seeded accounts use the development-only password `MotoCareDev123!`; never reuse it outside local development.

To verify the PostGIS nearest-provider query:

```powershell
npm run db:check-nearest-provider
```

The check filters approved online providers with `ST_DWithin` and verifies that the result is sorted by `ST_Distance`.

All price and wallet columns use PostgreSQL `numeric`/`decimal`, never floating-point types. Location columns use `geography(Point, 4326)` with GiST indexes.
