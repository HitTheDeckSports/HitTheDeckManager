import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import 'app_environment.dart';
import 'firebase_options_production.dart';

abstract final class FirebaseEnvironmentOptions {
  static FirebaseOptions get currentPlatform {
    return forEnvironment(AppEnvironmentConfig.current);
  }

  static FirebaseOptions forEnvironment(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.development:
        return DefaultFirebaseOptions.currentPlatform;
      case AppEnvironment.production:
        return ProductionFirebaseOptions.currentPlatform;
    }
  }
}
