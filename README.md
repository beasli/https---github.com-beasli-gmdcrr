# GMDCRR - Village Survey App

A Flutter application designed for conducting comprehensive village surveys. This application allows surveyors to collect data regarding families, accommodation, land ownership, assets, livestock, income, and expenses.

## Features

- **Family Survey**: Detailed forms for family members, relationships, and demographics.
- **Asset Management**: Record land details, trees, household assets, and livestock.
- **Offline Support**: Data is saved locally using SQLite when offline and can be synced when connectivity is available.
- **Location & Media**: Captures GPS coordinates, photos of assets/members, and digital signatures.
- **Authentication**: Secure login for surveyors.

## Getting Started

### Prerequisites

- Flutter SDK (^3.10.0)
- Dart SDK

### Installation

1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```

## Build Commands

### Staging Build

To build the release APK for the staging environment, use the following command:

```bash
flutter build apk --release --dart-define=ENV=staging
```

This command uses `dart-define` to set the environment variable `ENV` to `staging` during the build process.