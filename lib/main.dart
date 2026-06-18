import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'core/services/notification_services/notification_services.dart';
import 'features/app_gate_way/app_gate_way.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    Firebase.initializeApp(),
    NotificationService.instance.registerBackgroundHandler(),
    init(),
  ]);
  runApp(const AppGateway());
}
