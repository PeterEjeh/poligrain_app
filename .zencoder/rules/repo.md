# Repository Info: poligrain_app

Last updated: 2025-09-10

## Overview

Poligrain is a Flutter application with a backend powered by AWS Amplify. It targets multiple platforms (Android, iOS, Web, Windows, macOS, Linux) and implements features such as campaigns, products, orders, inventory reservations, investments, transactions, documents, and email notifications.

## Tech Stack

- **Frontend**: Flutter/Dart (`lib/`)
- **Backend**: AWS Amplify (`amplify/`)
  - API Gateway + Lambda functions (Node.js/JS in Amplify functions; historical TypeScript in `functions_backup/`)
  - Cognito Auth, S3 Storage
- **Tests**: Flutter test (`test/`)

## Key Directories

- **lib/**: Application code
  - **models/**: Core data models (campaign, product, order, etc.)
  - **services/**: Business logic and API integration (campaign, inventory reservation, investment, order, receipt, transaction, etc.)
  - **screens/**: UI flows (auth, cart, marketplace, crowdfunding, logistics, onboarding, profile)
  - **widgets/** and **utils/**: Reusable UI and helpers
  - **amplifyconfiguration.dart / amplify_outputs.dart**: Amplify client config
- **amplify/**: Infrastructure-as-code and Lambda sources
  - **backend/function/**: Lambda handlers (CampaignHandler, OrderHandler, TransactionHandler, ProductHandler, InventoryReservationHandler, DocumentHandler, EmailHandler, InvestmentHandler, loanHandler, createUserProfileTrigger, profileHandler, etc.)
  - **backend/api/**: API configs
  - **backend/auth/**: Cognito configs
  - **backend/storage/**: S3 bucket configs
- **platforms**: `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`
- **test/**: Unit and widget tests

## Notable Files

- **README.md**: Default Flutter readme (consider updating)
- **pubspec.yaml**: Flutter dependencies and assets
- **amplify/team-provider-info.json**: Environment-specific Amplify settings
- **amplify/backend/backend-config.json**: Amplify resources map
- **.gitignore**: Ensure secrets and build artifacts are excluded

## Running the App (local)

1. Install Flutter and set up a device or Chrome for web.
2. From repo root:
   - `flutter pub get`
   - `flutter run` (e.g., `flutter run -d chrome` for Web)
3. Amplify backend:
   - Ensure the Amplify environment is initialized on your machine (`amplify init`) or pull existing env (`amplify pull`).
   - Deploy/update resources as needed: `amplify push`.

## Testing

- Run unit/widget tests: `flutter test`

## Deployment

- Web: `flutter build web`
- Android: `flutter build apk` or `flutter build appbundle`
- iOS: `flutter build ios` (requires macOS)
- Windows/macOS/Linux: respective `flutter build <platform>`

## Conventions & Tips

- Keep Amplify client files (`lib/amplifyconfiguration.dart`, `lib/amplify_outputs.dart`) in sync with the current environment.
- Lambda functions managed by Amplify live under `amplify/backend/function/<FunctionName>/src`.
- Historical or reference serverless code exists in `functions_backup/` (TypeScript); prefer the Amplify-managed functions under `amplify/`.
- Update this file when adding major features, services, or backend resources.
