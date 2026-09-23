import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import 'app_environment.dart';

abstract final class FirebaseEnvironmentOptions {
  static FirebaseOptions get currentPlatform {
    return forEnvironment(AppEnvironmentConfig.current);
  }

  static FirebaseOptions forEnvironment(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.development:
        return DefaultFirebaseOptions.currentPlatform;
      case AppEnvironment.production:
        throw StateError(
          'Production Firebase is not configured yet. '
          'Phase 7 must install the Production Firebase options before '
          'building with --dart-define=APP_ENV=production.',
        );
    }
  }
}
