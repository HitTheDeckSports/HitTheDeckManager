# Phase 7 Firebase Environments

Hit the Deck Manager uses compile-time environment selection.

## Supported environments

- `development`
- `production`

There is intentionally no in-app environment switch.

## Firebase project aliases

```text
default -> hit-the-deck-manager
dev     -> hit-the-deck-manager
prod    -> hit-the-deck-manager-prod
```

The Development project remains the default. Production commands should use an
explicit project or the `prod` alias.

## Development

```powershell
flutter run
```

is equivalent to:

```powershell
flutter run --dart-define=APP_ENV=development
```

Development resolves to:

```text
hit-the-deck-manager
```

## Production

Production builds must be explicit:

```powershell
flutter run --dart-define=APP_ENV=production
```

Production resolves to:

```text
hit-the-deck-manager-prod
```

Registered V1.0 Production client apps:

```text
Android
  Package: com.hitthedecksports.manager
  App ID: 1:738646463284:android:0088c02725de6d375fcb61

Windows (Firebase Web configuration)
  App ID: 1:738646463284:web:d38987d805fbb0dc5fcb61
```

Android and Windows are the V1.0 release targets. iOS/macOS Production Firebase
registration is intentionally deferred.

## Native Android configuration

This checkpoint does not replace `android/app/google-services.json`.
Development native Android configuration remains untouched until the dedicated
Android environment/signing checkpoint.

The Dart bootstrap uses explicit `FirebaseOptions`, so `APP_ENV=production`
resolves application initialization to the Production Firebase project.

## Safety rule

A Production build must never silently use Development Firebase, and normal
Development builds must continue to use the Development project.
