import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvironmentService {
  static Environment _currentEnv = Environment.local;
  static void setEnvironment(Environment env) => _currentEnv = env;

  // - 192.168.0.2:5000 (Current Wi-Fi LAN IP). Override with --dart-define=BACKEND_IP=<ip>.
  // - 127.0.0.1:5000 with `adb reverse tcp:5000 tcp:5000` enables stable connection over USB
  static const String localHostIp = String.fromEnvironment('BACKEND_IP', defaultValue: "192.168.0.2");
  static const String localPort = String.fromEnvironment('BACKEND_PORT', defaultValue: "5000");
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String geminiModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.8-flash');
  static String? _customBaseUrl;

  /// The API that release builds (TestFlight and the stores) talk to.
  /// This is the live server (Azure "Clinicx-api-dev", deployed from the 22-04-2026-Dev branch).
  static const String productionBaseUrl = "https://clinicx-api-dev.azurewebsites.net";

  /// Release builds use production; debug runs use the local backend.
  /// Override with --dart-define=APP_ENV=local|dev|qa|production.
  static Environment get buildEnvironment {
    const name = String.fromEnvironment('APP_ENV');
    for (final env in Environment.values) {
      if (env.name == name) return env;
    }
    return kReleaseMode ? Environment.production : Environment.local;
  }

  static void setCustomBaseUrl(String? url) => _customBaseUrl = url;

  /// Probes available local channels:
  /// 1. 192.168.0.5:5000 (Current Wi-Fi LAN)
  /// 2. 127.0.0.1:5000 (direct USB tunnel via `adb reverse tcp:5000 tcp:5000`)
  /// 3. Fallback candidates (192.168.0.4, 192.168.0.7, 192.168.0.3, 192.168.0.6, 10.0.2.2)
  static Future<void> autoDetectLocalHost({bool force = true}) async {
    if (_currentEnv != Environment.local) return;
    if (!force && _customBaseUrl != null && _customBaseUrl!.isNotEmpty) return;
    _customBaseUrl = null;

    final candidates = [
      localHostIp,
      '192.168.0.2',
      '192.168.0.5',
      '127.0.0.1',
      '192.168.0.4',
      '192.168.0.7',
      '192.168.0.3',
      '192.168.0.6',
      '10.0.2.2',
    ];

    final port = int.tryParse(localPort) ?? 5000;

    for (final host in candidates) {
      try {
        final socket = await Socket.connect(host, port, timeout: const Duration(milliseconds: 800));
        socket.destroy();
        _customBaseUrl = "http://$host:$localPort";
        if (host == '127.0.0.1') {
          debugPrint('[Environment] 🚀 Connected via USB adb reverse: $_customBaseUrl');
        } else {
          debugPrint('[Environment] 🌐 Connected via LAN: $_customBaseUrl');
        }
        return;
      } catch (_) {}
    }

    _customBaseUrl = "http://$localHostIp:$localPort";
    debugPrint('[Environment] ⚠️ Using local fallback URL: $_customBaseUrl');
  }

  static String get _localHostUrl {
    if (_customBaseUrl != null && _customBaseUrl!.trim().isNotEmpty) {
      return _customBaseUrl!.trim();
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
        const envUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
        final devUrl = _customBaseUrl ?? (envUrl.isNotEmpty ? envUrl.trim() : "https://clinicx-api-dev.azurewebsites.net");
        return EnvironmentConfig(
          accountBaseUrl: devUrl,
          healthCampBaseUrl: devUrl,
        );
      case Environment.qa:
        return const EnvironmentConfig(
          accountBaseUrl: "https://clinicx-api-qa.azurewebsites.net",
          healthCampBaseUrl: "https://clinicx-api-qa.azurewebsites.net",
        );
      case Environment.production:
        return const EnvironmentConfig(
          accountBaseUrl: productionBaseUrl,
          healthCampBaseUrl: productionBaseUrl,
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
