import 'package:flutter/material.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'features/app_gate_way/app_gate_way.dart';

// Theme Imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  runApp(const AppGateway());
}

