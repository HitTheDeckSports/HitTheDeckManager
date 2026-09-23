# Windows Release

The Windows V1.0 application identity is:

```text
Product name: Hit the Deck Manager
Company: Hit the Deck Sports
Executable: HitTheDeckManager.exe
Window title: Hit the Deck Manager
```

Production Windows builds must use the Production Firebase environment:

```powershell
flutter build windows --release --dart-define=APP_ENV=production
```

Google Sign-In on Windows additionally requires the environment-specific
`GOOGLE_WINDOWS_CLIENT_ID` and `GOOGLE_WINDOWS_CLIENT_SECRET` dart-defines.
Those OAuth credentials are configured and validated in a separate Phase 7
checkpoint and must not be committed to source control.

Development Windows builds continue to use:

```powershell
flutter run -d windows --dart-define=APP_ENV=development
```
