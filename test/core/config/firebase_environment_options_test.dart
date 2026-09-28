import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/config/app_environment.dart';
import 'package:hit_the_deck_manager/core/config/firebase_environment_options.dart';
import 'package:hit_the_deck_manager/core/config/firebase_options_production.dart';

void main() {
  group('FirebaseEnvironmentOptions', () {
    test('development resolves to existing development Firebase project', () {
      final options = FirebaseEnvironmentOptions.forEnvironment(
        AppEnvironment.development,
      );
      expect(options.projectId, 'hit-the-deck-manager');
    });

    test('production resolves to production Firebase project', () {
      final options = FirebaseEnvironmentOptions.forEnvironment(
        AppEnvironment.production,
      );
      expect(options.projectId, 'hit-the-deck-manager-prod');
      expect(options.projectId, isNot('hit-the-deck-manager'));
    });

    test('production Android options match registered app', () {
      expect(
        ProductionFirebaseOptions.android.appId,
        '1:738646463284:android:0088c02725de6d375fcb61',
      );
    });

    test('production Windows options match registered web app', () {
      expect(
        ProductionFirebaseOptions.windows.appId,
        '1:738646463284:web:d38987d805fbb0dc5fcb61',
      );
    });

    test('development and production use different project IDs', () {
      final dev = FirebaseEnvironmentOptions.forEnvironment(
        AppEnvironment.development,
      );
      final prod = FirebaseEnvironmentOptions.forEnvironment(
        AppEnvironment.production,
      );
      expect(dev.projectId, isNot(prod.projectId));
    });
  });
}
