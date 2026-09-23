# Phase 7 Firebase Environments

Firebase CLI aliases:

```text
default -> hit-the-deck-manager
dev     -> hit-the-deck-manager
prod    -> hit-the-deck-manager-prod
```

Dart uses `APP_ENV=development|production`.

Android additionally requires a matching Gradle flavor:

```text
dev  -> hit-the-deck-manager
prod -> hit-the-deck-manager-prod
```

Development Android:
```powershell
flutter run --flavor dev --dart-define=APP_ENV=development
```

Production Android:
```powershell
flutter build appbundle --release --flavor prod --dart-define=APP_ENV=production
```

The root `android/app/google-services.json` is intentionally removed so Android
builds must select a flavor explicitly.

Windows uses only the Dart compile-time environment:
```powershell
flutter run -d windows --dart-define=APP_ENV=development
flutter build windows --release --dart-define=APP_ENV=production
```

Safety rule: Production must never silently use Development Firebase.
