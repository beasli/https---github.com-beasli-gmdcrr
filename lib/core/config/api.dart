// Central place for API-related constants.
// This value can be overridden at compile time using --dart-define=API_ENV=dev|staging|prod
const String _kApiEnv = String.fromEnvironment('API_ENV', defaultValue: 'prod');

/// Base URLs per environment. Edit or extend as needed.
const Map<String, String> _kEnvToBase = {
	'dev': 'https://api-gmdc-lams.lgeom.com/v1',
	'staging': 'https://api-gmdc-lgeom.com/v1',
	'prod': 'https://api-gmdc-lams.lgeom.com/v1',
};

String get kApiBaseUrl => _kEnvToBase[_kApiEnv] ?? _kEnvToBase['prod']!;
