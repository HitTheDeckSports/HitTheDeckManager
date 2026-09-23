import 'package:flutter_test/flutter_test.dart';
import 'package:hit_the_deck_manager/core/config/app_environment.dart';

void main() {
  group('AppEnvironmentConfig', () {
    test('parses development values', () {
      expect(
        AppEnvironmentConfig.parse('development'),
        AppEnvironment.development,
      );
      expect(AppEnvironmentConfig.parse('DEV'), AppEnvironment.development);
    });

    test('parses production values', () {
      expect(
        AppEnvironmentConfig.parse('production'),
        AppEnvironment.production,
      );
      expect(AppEnvironmentConfig.parse('prod'), AppEnvironment.production);
    });

    test('rejects unsupported values', () {
      expect(
        () => AppEnvironmentConfig.parse('staging'),
        throwsA(isA<StateError>()),
      );
    });

    test('default build environment is development', () {
      expect(AppEnvironmentConfig.current, AppEnvironment.development);
      expect(AppEnvironmentConfig.current.isDevelopment, isTrue);
      expect(AppEnvironmentConfig.current.isProduction, isFalse);
    });
  });
}
