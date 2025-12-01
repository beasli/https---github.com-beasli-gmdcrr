/// Defines the application's build environment.
enum Environment {
  development,
  staging,
  production,
}

/// A singleton class to hold and manage environment-specific configurations.
class AppConfig {
  // Private constructor
  AppConfig._();

  // The single instance of the class
  static final AppConfig _instance = AppConfig._();

  // Factory constructor to return the same instance
  factory AppConfig() => _instance;

  // The name of the environment, passed via --dart-define=ENV=...
  static const String _envName = String.fromEnvironment('ENV', defaultValue: 'production');

  /// The current build environment.
  static Environment get currentEnvironment {
    if (_envName == 'staging') return Environment.staging;
    if (_envName == 'development') return Environment.development;
    return Environment.production;
  }

  /// The API base URL for the current environment.
  static String get baseUrl {
    if (currentEnvironment == Environment.staging) return 'https://api-gmdc-lams.lgeom.com/v1'; // Replace with your staging URL
    if (currentEnvironment == Environment.development) return 'https://api-gmdc-lams.lgeom.com/v1'; // Replace with your dev URL
    return 'https://api-gmdc-lams.lgeom.com/v1'; // Your production URL
  }
}