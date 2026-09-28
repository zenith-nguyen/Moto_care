# MotoCare Backend

NestJS API for the MotoCare motorbike roadside-assistance application. The Flutter mobile app is maintained in a separate repository.

## Local development

1. Copy `.env.example` to `.env` and replace `JWT_SECRET` with a unique value of at least 32 characters.
2. Start Postgres with PostGIS: `docker compose up -d`.
3. Install packages: `npm ci`.
4. Apply migrations: `npm run migration:run`.
5. Start the API: `npm run start:dev`.

The API is available at `http://localhost:3000`, its health probe at `/health`, and Swagger UI at `/docs`.

## Quality checks

```bash
npm run lint
npm test
npm run build
```

The GitHub Actions workflow runs these checks for pull requests and updates to `main` or `feat/**` branches. Changes must be proposed through a PR using Conventional Commits.

## Database

Local development uses `postgis/postgis:16-3.4`. TypeORM always uses migrations; `synchronize` is disabled. The first migration enables the PostGIS extension, and the second creates the minimal `users` table required by Auth.
