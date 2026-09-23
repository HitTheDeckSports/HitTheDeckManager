import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/config/app_environment.dart';
import 'package:hit_the_deck_manager/core/config/firebase_environment_options.dart';

void main() {
  group('FirebaseEnvironmentOptions', () {
    test('development resolves to existing Firebase project', () {
      final options = FirebaseEnvironmentOptions.forEnvironment(
        AppEnvironment.development,
      );
      expect(options.projectId, 'hit-the-deck-manager');
    });

    test('production fails closed until configured', () {
      expect(
        () => FirebaseEnvironmentOptions.forEnvironment(
          AppEnvironment.production,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
