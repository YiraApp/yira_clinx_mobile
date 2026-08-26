class EnvironmentService {
  static Environment _currentEnv = Environment.qa;
  static void setEnvironment(Environment env) => _currentEnv = env;
  static EnvironmentConfig get config {
    switch (_currentEnv) {
      case Environment.dev:
        return const EnvironmentConfig(
<<<<<<< HEAD
          accountBaseUrl: "192.168.68.78:5000",
          healthCampBaseUrl: "192.168.68.78:5000",
        );
      case Environment.qa:
        return const EnvironmentConfig(
          accountBaseUrl: "192.168.68.78:5000",
          healthCampBaseUrl: "192.168.68.78:5000",
        );
      case Environment.production:
        return const EnvironmentConfig(
          accountBaseUrl: "192.168.68.78:5000",
          healthCampBaseUrl: "192.168.68.78:5000",
=======
          accountBaseUrl: "192.168.0.103:5000",
          healthCampBaseUrl: "192.168.0.103:5000",
        );
      case Environment.qa:
        return const EnvironmentConfig(
          accountBaseUrl: "192.168.0.103:5000",
          healthCampBaseUrl: "192.168.0.103:5000",
        );
      case Environment.production:
        return const EnvironmentConfig(
          accountBaseUrl: "192.168.0.103:5000",
          healthCampBaseUrl: "192.168.0.103:5000",
>>>>>>> 99e3a37a0a89507b29eeb97d9710867810e54811
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