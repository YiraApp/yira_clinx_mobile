import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvironmentService {
  static Environment _currentEnv = Environment.local;
  static void setEnvironment(Environment env) => _currentEnv = env;

  static String get _localHostUrl {
    // 192.168.68.109 connects physical devices (moto g62 5G) over Wi-Fi, and localhost works via adb reverse
    return "http://192.168.68.109:5000";
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
          accountBaseUrl: "clinicx-api-qa.azurewebsites.net",
          healthCampBaseUrl: "clinicx-api-qa.azurewebsites.net",
        );
      case Environment.qa:
        return const EnvironmentConfig(
          accountBaseUrl: "clinicx-api-qa.azurewebsites.net",
          healthCampBaseUrl: "clinicx-api-qa.azurewebsites.net",
        );
      case Environment.production:
        return const EnvironmentConfig(
          accountBaseUrl: "clinicx-api-qa.azurewebsites.net",
          healthCampBaseUrl: "clinicx-api-qa.azurewebsites.net",
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