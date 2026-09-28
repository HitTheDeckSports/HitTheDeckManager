# Android Release Signing and Firebase Flavors

Android uses two product flavors:

```text
dev  -> Development Firebase
prod -> Production Firebase
```

Both use application ID `com.hitthedecksports.manager`.

Development:
```powershell
flutter run --flavor dev --dart-define=APP_ENV=development
```

Production:
```powershell
flutter build appbundle --release --flavor prod --dart-define=APP_ENV=production
```

Native Firebase files:
```text
android/app/src/dev/google-services.json
android/app/src/prod/google-services.json
```

Release keystore:
```text
%USERPROFILE%\.hitthedeck\keys\hit-the-deck-manager-upload.jks
```

Local signing credentials:
```text
android/key.properties
```

`android/key.properties`, `.jks`, and `.keystore` files are ignored by Git.

When Google Play App Signing is enabled, add Google Play's app-signing SHA-1
and SHA-256 to the Production Firebase Android app as well.
