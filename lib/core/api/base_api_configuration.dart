
class EnvironmentService {
  static Environment _currentEnv = Environment.production;
  static void setEnvironment(Environment env) => _currentEnv = env;
  static EnvironmentConfig get config {
    switch (_currentEnv) {
      case Environment.dev:
        return const EnvironmentConfig(
          accountBaseUrl: "yiraapi.azurewebsites.net",
          healthCampBaseUrl: "yiraapi.azurewebsites.net",
        );
      case Environment.qa:
        return const EnvironmentConfig(
          accountBaseUrl: "yiraapi.azurewebsites.net",
          healthCampBaseUrl: "yiraapi.azurewebsites.net",
        );
      case Environment.production:
        return const EnvironmentConfig(
          accountBaseUrl: "yiraapi.azurewebsites.net",
          healthCampBaseUrl: "yiraapi.azurewebsites.net"
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