enum AppEnvironment {
  development,
  production;

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isProduction => this == AppEnvironment.production;
}

abstract final class AppEnvironmentConfig {
  static const String _rawEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get current => parse(_rawEnvironment);

  static AppEnvironment parse(String value) {
    switch (value.trim().toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      default:
        throw StateError(
          'Unsupported APP_ENV "$value". Use development or production.',
        );
    }
  }
}
