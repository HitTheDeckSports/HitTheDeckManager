# Phase 7 Firebase Environments

Hit the Deck Manager uses compile-time environment selection.

## Supported environments

- `development`
- `production`

There is intentionally no in-app environment switch.

## Development

Development is the default:

```powershell
flutter run
```

Equivalent explicit command:

```powershell
flutter run --dart-define=APP_ENV=development
```

Development currently resolves to Firebase project:

```text
hit-the-deck-manager
```

## Production

Production builds must be explicit:

```powershell
flutter run --dart-define=APP_ENV=production
```

During Phase 7A1, Production intentionally fails closed because Production
Firebase credentials have not yet been installed. This prevents a production
build from silently falling back to Development Firebase.

Phase 7A2/7B will install the actual Production Firebase options.

## Safety rule

A Production build must never silently use Development Firebase.
