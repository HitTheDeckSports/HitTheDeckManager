# Continuous Integration

GitHub Actions runs the repository's core automated checks on every push and on
pull requests targeting `develop`.

Workflow:

```text
.github/workflows/ci.yml
```

## Flutter quality job

The Flutter job uses Flutter `3.44.8` and Java 17 and runs:

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --flavor dev --dart-define=APP_ENV=development
```

The Android build intentionally uses the Development flavor and Development
Firebase configuration. Production credentials and the private Android signing
key are never required by CI.

## Firebase security-rules job

The Firebase job uses Node 22, Java 21, and Firebase CLI `15.30.2`. It runs:

```text
npm ci
npm run test:security-rules
```

The security-rule tests use the local Firebase emulator demo project. They do
not access Development or Production Firebase data.

## Production release builds

Production Android and Windows release artifacts remain manual Phase 7 release
steps. GitHub Actions does not store the Android signing key, Android signing
passwords, or Windows OAuth client secret.

This is intentional for the V1.0 private-distribution model.
