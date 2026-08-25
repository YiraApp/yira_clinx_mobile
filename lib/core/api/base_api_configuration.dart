class EnvironmentService {
  static Environment _currentEnv = Environment.qa;
  static void setEnvironment(Environment env) => _currentEnv = env;
  static EnvironmentConfig get config {
    switch (_currentEnv) {
      case Environment.dev:
        return const EnvironmentConfig(
          accountBaseUrl: "192.168.68.63:5000",
          healthCampBaseUrl: "192.168.68.63:5000",
        );
      case Environment.qa:
        return const EnvironmentConfig(
          accountBaseUrl: "192.168.68.63:5000",
          healthCampBaseUrl: "192.168.68.63:5000",
        );
      case Environment.production:
        return const EnvironmentConfig(
          accountBaseUrl: "192.168.68.63:5000",
          healthCampBaseUrl: "192.168.68.63:5000",
        );
    }
  }
}
enum Environment { dev, qa, production }

class EnvironmentConfig {
  final String accountBaseUrl;
  final String healthCampBaseUrl;

  const EnvironmentConfig({
    required this.accountBaseUrl,
    required this.healthCampBaseUrl,
  });
}