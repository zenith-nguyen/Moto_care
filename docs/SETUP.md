# Setting the project up from a fresh clone

Everything below runs locally with no credential from the project owner. No
SePay account, no production secret and no access to the owner's server is
needed: the sample configuration is complete enough to register, request a
rescue, match a mechanic, pay in simulation and finish an order.

## 1. Prerequisites

| Tool | Version | Why |
|---|---|---|
| Flutter SDK | stable channel, Dart `^3.13.2` | both mobile apps |
| Node.js | 22 or newer | the API (`backend/package.json` declares `>=22`) |
| Docker | any recent version | PostgreSQL + PostGIS for the API |
| JDK | 17 | Android builds |
| Android Studio | any recent version | emulator and Android SDK |

Check Flutter's own diagnosis first; it reports a missing Android SDK, an
unaccepted licence or a missing emulator better than any instruction here can:

```bash
flutter doctor
```

## 2. Clone

```bash
git clone https://github.com/zenith-nguyen/Moto_care.git
cd Moto_care
```

The Flutter app is the repository root; the NestJS API is `backend/`.

## 3. Database

```bash
cd backend
docker compose up -d
docker compose ps        # wait until the service reports (healthy)
```

This starts PostgreSQL 16 with PostGIS as container `motocare-postgres` on port
5432, with data in a named volume that survives restarts. PostGIS is required,
not optional: matching searches mechanics by distance.

## 4. API configuration

```bash
cp .env.example .env
```

The sample values are enough for local development. Two things are worth
knowing before editing it:

- `DEMO_MODE=false` and `SEPAY_ENABLED=false` in the sample mean payments run in
  simulation. Nothing contacts a bank, and no real money can move.
- The production values (SePay account, webhook secret, SMTP password, JWT
  secret) are deliberately not in the repository. Their names and purpose are
  documented in `.env.example`; see `CHAM-DIEM.md` for why they are withheld.

## 5. Run the API

```bash
npm ci
npm run migration:run     # creates the schema
npm run seed              # demo accounts, incident types, skills, stations
npm run start:dev
```

The API listens on `http://localhost:3000`. Its OpenAPI documentation is served
at `http://localhost:3000/docs` outside production.

### Seeded accounts

`npm run seed` creates five accounts. With the sample configuration every one of
them uses the password `MotoCareDev123!`:

| Email | Role | Signs in to |
|---|---|---|
| `customer@motocare.local` | customer | customer app |
| `admin@motocare.local` | administrator | customer app (opens the admin shell) |
| `provider.q1@motocare.local` | mechanic, District 1 | provider app |
| `provider.binhthanh@motocare.local` | mechanic, Binh Thanh | provider app |
| `provider.phunhuan@motocare.local` | mechanic, Phu Nhuan | provider app |

There is no separate admin application. Signing into the customer app with the
administrator account opens the admin shell instead of the customer home.

## 6. Run the apps

The Android build declares two flavors, so a flavor and an entrypoint are always
required; `flutter run` on its own fails.

```bash
cd ..
flutter pub get

# Customer app (and the admin console)
flutter run --flavor customer -t lib/main.dart

# Provider app
flutter run --flavor provider -t lib/main_provider.dart
```

In debug builds `API_BASE_URL` defaults to `http://10.0.2.2:3000`, which is how
an Android emulator reaches a server on the host machine. A physical device
cannot use that address: build it with the machine's address on the same
network, or with a public HTTPS URL.

```bash
flutter run --flavor customer -t lib/main.dart \
  --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

Release builds refuse to start without an HTTPS `API_BASE_URL`. See the release
section of [`../README.md`](../README.md).

Maps work without any Google key: the app falls back to OpenStreetMap tiles.
Supplying a key switches to Google Maps and enables place search, as described
in [`LOCATION.md`](LOCATION.md).

## 7. See a full rescue end to end

Two emulators make the whole flow visible:

1. On the first, run the provider app, sign in as `provider.q1@motocare.local`
   and go online. Going online requires a recent position, so let the emulator
   send a location (Extended controls, Location) first.
2. On the second, run the customer app, sign in as `customer@motocare.local`,
   request a rescue and confirm the simulated prepayment.
3. The order is offered to every eligible mechanic nearby; accept it on the
   provider side. Progress it through arrival, the start code the customer
   shows, the final price and completion.
4. Sign in as `admin@motocare.local` in the customer app to see the same order
   in the admin console.

## 8. Run the tests

No credentials, no network and no running API are needed for any of these.

```bash
# Mobile app: 462 tests
flutter test
flutter analyze

# API: 66 unit tests
cd backend
npm test
npm run lint
npm run typecheck

# API against a real database (requires step 3)
npm run test:db
```

The database suite refuses to run against your development database. It uses
the separate one named by `TEST_DATABASE_NAME`, whose name must match
`motocare_*test`, and it does not create that database or its schema. Prepare it
once:

```bash
cd backend
docker compose exec postgres psql -U motocare -d postgres \
  -c "CREATE DATABASE motocare_local_test;"
docker compose exec postgres psql -U motocare -d motocare_local_test \
  -c "CREATE EXTENSION postgis;"
DATABASE_NAME=motocare_local_test npm run migration:run
npm run test:db
```

Re-run that migration line whenever a new migration is added, otherwise the
suite fails with `relation ... does not exist`.

The exact environment CI uses for the database suite is in
`.github/workflows/backend-ci.yml` under `env:`. Every value there is a
test-only placeholder and can be copied verbatim; CI points `DATABASE_NAME` and
`TEST_DATABASE_NAME` at the same throwaway database, which is why it needs no
separate preparation step.

## 9. When something fails

| Symptom | Cause and fix |
|---|---|
| `ECONNREFUSED ... :5432` | The database container is not running. `cd backend && docker compose up -d`. |
| `Cannot find a flavor` / the app refuses to start | A flavor and an entrypoint are required. Use the commands in step 6. |
| Login fails in the app but the API is up | The emulator cannot reach `10.0.2.2` (a physical device, or a non-standard emulator). Pass `--dart-define=API_BASE_URL=...`. |
| `relation ... does not exist` | Migrations were not run. `npm run migration:run`. |
| Seed fails demanding long passwords | `DEMO_MODE=true` requires three distinct `SEED_*_PASSWORD` values of at least 16 characters. The sample `.env` leaves demo mode off and does not need them. |
| Port 3000 already in use | Change `PORT` in `backend/.env`, and pass the matching `API_BASE_URL` to the app. |
| The installed APK cannot sign in | Those builds point at the owner's server, which is not online permanently. Build locally instead, as above. |

## 10. Before changing anything

Read [`SPECS.md`](SPECS.md). `openspec/specs/` states what each capability must
do, and a behaviour change goes through a proposal under `openspec/changes/`
rather than straight into the code. Branch and review rules are in
[`WORKFLOW.md`](WORKFLOW.md).
