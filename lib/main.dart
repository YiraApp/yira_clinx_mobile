import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'core/api/base_api_configuration.dart';
import 'core/local/global_session.dart';
import 'core/services/notification_services/notification_services.dart';
import 'features/app_gate_way/app_gate_way.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvironmentService.setEnvironment(Environment.qa);

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
  }
  GlobalSession.instance.initializePlatformTelemetry();
  runApp(const AppGateway());
}