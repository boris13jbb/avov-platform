class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.appName,
  });

  final String apiBaseUrl;
  final String appName;

  static const AppConfig development = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000/api/v1',
    ),
    appName: 'AVOV',
  );
}
