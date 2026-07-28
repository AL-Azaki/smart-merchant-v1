# QA Access Mode

## What QA Access Mode is
QA Access Mode is a dedicated development capability that allows developers and QA testers to bypass the Laravel authentication and application initialization flows. When enabled, it creates a fully self-consistent local session utilizing seeded deterministic data in SQLite, simulating a real signed-in session for the ERP.

## Why it exists
This mode exists to allow rapid testing and iteration of the core ERP modules (Sales, Inventory, Accounting) on physical devices or emulators without requiring a connection to the development Laravel backend, speeding up testing and enabling offline development work.

## How it is isolated from production
QA Access Mode is structurally isolated by the `AppEnvironment` configuration.
The bypass is governed by the `ENABLE_QA_AUTH_BYPASS` flag, which is ONLY respected if the `APP_ENV` is explicitly set to `qa` or `development`.
If the `APP_ENV` is set to `production` (which is the default behavior if omitted), the bypass logic is completely ignored, and the real Laravel authentication is strictly enforced. Furthermore, sync operations are guarded from ever pushing data to a production backend when QA bypass is enabled.

## How to run on physical Android
To run the application with QA Access Mode enabled:
```powershell
flutter run -d <device-id> --dart-define=APP_ENV=qa --dart-define=ENABLE_QA_AUTH_BYPASS=true
```

## How to build team QA APK
To build an APK for the QA team to test offline, run:
```powershell
flutter build apk --dart-define=APP_ENV=qa --dart-define=ENABLE_QA_AUTH_BYPASS=true
```

## How to test real Laravel auth
To run the application and test the real authentication flows with Laravel:
```powershell
flutter run --dart-define=APP_ENV=development --dart-define=ENABLE_QA_AUTH_BYPASS=false
```

## How to build production
Production builds must be executed with QA bypass explicitly disabled and the environment set to production:
```powershell
flutter build apk --dart-define=APP_ENV=production --dart-define=ENABLE_QA_AUTH_BYPASS=false
```

## How to reset QA data
To reset the QA data, you must clear the application data on the device or emulator since the seeder is idempotent. On Android, go to Settings -> Apps -> Smart Merchant ERP -> Storage -> Clear Data, and then relaunch the application. This ensures a completely fresh SQLite database.

## How sync is protected
The `SyncCoordinator` contains an explicit QA Sync Safety Guard. If QA bypass is enabled, any attempt to run a full sync against an environment named `production` or a base URL containing the production domain (`api.smartmerchant.app`) is automatically blocked, returning a fake offline status.

## How to disable QA mode permanently for production
QA mode is disabled by default. If `APP_ENV` is omitted or set to `production`, QA mode is ignored regardless of the `ENABLE_QA_AUTH_BYPASS` flag. However, for utmost security, production CI/CD pipelines should explicitly pass `--dart-define=APP_ENV=production --dart-define=ENABLE_QA_AUTH_BYPASS=false`.
