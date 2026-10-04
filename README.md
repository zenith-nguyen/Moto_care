# Moto Care

Moto Care is a mobile roadside-assistance application for motorbike riders. It connects customers who need help with nearby approved mobile mechanics.

This repository is the MotoCare monorepo. The Flutter mobile application lives at the repository root, and the NestJS API lives in `backend/`.

The backend uses PostgreSQL + PostGIS locally through Docker Compose. See [`backend/README.md`](backend/README.md) for backend setup and database commands.

## Product scope

Customers can request help for incidents such as an empty fuel tank, flat tire, engine failure, dead battery, or minor collision. Before confirming a request, the application shows a transparent estimated price. After a mechanic accepts the request, the customer can track the mechanic in real time, chat, confirm the service by QR code, pay, and leave a review.

The application supports three roles:

- **Customer**: creates SOS requests, tracks a mechanic, chats, pays, reviews, and views service history.
- **Provider**: accepts nearby requests, manages service progress and extra costs, views earnings, and requests withdrawals. Providers must be approved by an administrator before accepting requests.
- **Administrator**: approves providers, reviews platform activity, handles complaints, and processes withdrawal requests.

## Mobile technology

- Flutter and Dart
- Riverpod for application state
- Go Router for navigation
- Dio for backend communication
- Secure Storage for credentials and tokens
- Flutter localization and `intl` for Vietnamese dates, currency, and UI

## Delivery target

The project is a one-month mobile-development course project. Its required final deliverable is an Android APK.

## Documentation

Project guides, contribution rules, AI instructions, CI/CD, and release procedures are maintained in [`docs/`](docs/README.md).

## Run locally

```bash
flutter pub get
flutter run
```
