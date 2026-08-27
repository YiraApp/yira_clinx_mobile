import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';

class PatientBookAppointmentSheet {
  static Future<void> show(BuildContext context, {VoidCallback? onAppointmentBooked}) async {
    await Navigator.pushNamed(context, AppRoutes.addAppointmentScreen);
    onAppointmentBooked?.call();
  }
}
