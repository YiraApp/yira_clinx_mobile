import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'core/api/base_api_configuration.dart';
import 'core/local/global_session.dart';
import 'core/services/notification_services/notification_services.dart';
import 'features/app_gate_way/app_gate_way.dart';
import 'features/presentation/medication_popup/medication_popup_overlay.dart';

/// Entry point for the floating medicine reminder shown over other apps
/// (Android). flutter_overlay_window runs it in its own engine.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedicationPopupApp());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  EnvironmentService.setEnvironment(Environment.local);
  debugPrint('[Environment] Initialized base URL: ${EnvironmentService.config.accountBaseUrl}');

  try {
    await Future.wait([
      Firebase.initializeApp(),
      NotificationService.instance.registerBackgroundHandler(),
    ]);
    await init();
    GlobalSession.instance.initializePlatformTelemetry();
    runApp(const AppGateway());
  } catch (e) {
    debugPrint('Initialization error: $e');
    GlobalSession.instance.initializePlatformTelemetry();
    runApp(const AppGateway());
  }
}