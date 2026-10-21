import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvironmentService {
  static Environment _currentEnv = Environment.local;
  static void setEnvironment(Environment env) => _currentEnv = env;

  // Local backend server URL for local development (matches local backend on port 5000)
  // - 127.0.0.1:5000 with `adb reverse tcp:5000 tcp:5000` enables 100% stable connection over USB, bypassing Wi-Fi AP isolation & firewall
  // - Or use Wi-Fi LAN IP (192.168.0.7) if running purely over wireless network
  static const String localHostIp = "192.168.0.7";
  static const String localPort = "5000";
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String? url) => _customBaseUrl = url;

  /// Probes available local channels:
  /// 1. 127.0.0.1:5000 (direct USB tunnel via `adb reverse tcp:5000 tcp:5000` - immune to Wi-Fi AP isolation)
  /// 2. 192.168.0.7:5000 (Current Wi-Fi LAN)
  /// 3. Fallback candidates (192.168.0.6, 192.168.0.4, 10.0.2.2)
  static Future<void> autoDetectLocalHost({bool force = true}) async {
    if (_currentEnv != Environment.local) return;
    if (!force && _customBaseUrl != null && _customBaseUrl!.isNotEmpty) return;
    _customBaseUrl = null;

    final candidates = [
      '127.0.0.1',
      localHostIp,
      '192.168.0.6',
      '192.168.0.4',
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

    if (!kIsWeb && Platform.isAndroid) {
      _customBaseUrl = "http://127.0.0.1:$localPort";
    } else {
      _customBaseUrl = "http://$localHostIp:$localPort";
    }
    debugPrint('[Environment] ⚠️ Using local URL: $_customBaseUrl');
  }

  static String get _localHostUrl {
    if (_customBaseUrl != null && _customBaseUrl!.trim().isNotEmpty) {
      return _customBaseUrl!.trim();
    }
    if (!kIsWeb && Platform.isAndroid) {
      return "http://127.0.0.1:$localPort";
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