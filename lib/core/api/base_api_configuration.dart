class EnvironmentService {
  static Environment _currentEnv = Environment.local;
  static void setEnvironment(Environment env) => _currentEnv = env;

  // Local backend server URL for local development (matches local backend on port 5000)
  // - 192.168.0.12:5000 (this Mac's Wi-Fi address) lets physical devices on the same Wi-Fi and
  //   emulators/simulators reach it. Override per run with --dart-define=BACKEND_IP=<ip>.
  static const String localHostIp = String.fromEnvironment('BACKEND_IP', defaultValue: "192.168.0.12");
  static const String localPort = String.fromEnvironment('BACKEND_PORT', defaultValue: "5000");
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String? url) => _customBaseUrl = url;

  static String get _localHostUrl {
    if (_customBaseUrl != null && _customBaseUrl!.trim().isNotEmpty) {
      return _customBaseUrl!.trim();
    }
    const envUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl.trim();
    }
    return "http://$localHostIp:$localPort";
  }

  static EnvironmentConfig get config {
    switch (_currentEnv) {
      case Environment.local:
        return EnvironmentConfig(
          accountBaseUrl: _localHostUrl,
          healthCampBaseUrl: _localHostUrl,
        );
      case Environment.dev:
        return const EnvironmentConfig(
          accountBaseUrl: "https://clinicx-api-dev.azurewebsites.net",
          healthCampBaseUrl: "https://clinicx-api-dev.azurewebsites.net",
        );
      case Environment.qa:
        return const EnvironmentConfig(
          accountBaseUrl: "https://clinicx-api-qa.azurewebsites.net",
          healthCampBaseUrl: "https://clinicx-api-qa.azurewebsites.net",
        );
      case Environment.production:
        return const EnvironmentConfig(
          accountBaseUrl: "https://clinicx-api-qa.azurewebsites.net",
          healthCampBaseUrl: "https://clinicx-api-qa.azurewebsites.net",
        );
    }
  }
}
enum Environment { local, dev, qa, production }

class EnvironmentConfig {
  final String accountBaseUrl;
  final String healthCampBaseUrl;

  const EnvironmentConfig({
    required this.accountBaseUrl,
    required this.healthCampBaseUrl,
  });
}