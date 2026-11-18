import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvironmentService {
  static Environment _currentEnv = Environment.local;
  static void setEnvironment(Environment env) => _currentEnv = env;

  // - 192.168.0.2:5000 (Current Wi-Fi LAN IP). Override with --dart-define=BACKEND_IP=<ip>.
  // - 127.0.0.1:5000 with `adb reverse tcp:5000 tcp:5000` enables stable connection over USB
  static const String localHostIp = String.fromEnvironment('BACKEND_IP', defaultValue: "192.168.0.2");
  static const String localPort = String.fromEnvironment('BACKEND_PORT', defaultValue: "5000");
  static String? _customBaseUrl;

  /// The API that release builds (TestFlight and the stores) talk to.
  static const String productionBaseUrl = "https://clinicsapi-fegha0fkfrcnfufu.centralindia-01.azurewebsites.net";

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
        // An open port 5000 isn't enough: other Macs on the Wi-Fi answer on it with AirPlay
        // ("AirTunes", 403), and the app then talked to them instead of the API.
        if (!await _isClinicxApi(host, port)) continue;
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

  /// Whether [host]:[port] is the Clinicx API: it answers in JSON (even a 401 for no token),
  /// unlike AirPlay or other services that happen to listen on the same port.
  static Future<bool> _isClinicxApi(String host, int port) async {
    final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 800);
    try {
      final request = await client.getUrl(Uri(scheme: 'http', host: host, port: port, path: '/'));
      final response = await request.close().timeout(const Duration(milliseconds: 1500));
      await response.drain<void>();
      return response.headers.contentType?.mimeType == 'application/json';
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
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
