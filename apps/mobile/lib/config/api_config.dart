/// API base URL and auth token for local development.
/// Override at build time: `--dart-define=API_BASE_URL=... --dart-define=ACCESS_TOKEN=...`
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const accessToken = String.fromEnvironment(
    'ACCESS_TOKEN',
    defaultValue: '',
  );
}
