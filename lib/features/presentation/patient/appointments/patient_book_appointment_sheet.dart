import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/liked_hospitals_service.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'patient_select_hospital_screen.dart';

class PatientBookAppointmentSheet {
  static Future<void> show(
    BuildContext context, {
    ProfileEntity? targetProfile,
    String? patientName,
    String? patientPhone,
    VoidCallback? onAppointmentBooked,
  }) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = (currentUser?.data?.id ?? '').trim();
    final effectiveName = patientName ??
        targetProfile?.name ??
        (targetProfile != null
            ? '${targetProfile.firstName ?? ''} ${targetProfile.lastName ?? ''}'.trim()
            : null);
    final effectivePhone = patientPhone ?? targetProfile?.phoneNumber;

    try {
      final hospitals = await LikedHospitalsService.instance.getLikedAndLinkedHospitals(patientId: userId);

      if (!context.mounted) return;

      if (hospitals.isNotEmpty) {
        // ALWAYS SHOW HOSPITALS FIRST -> THEN USER SELECTS A HOSPITAL TO VIEW ITS DOCTORS
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientSelectHospitalScreen(
              initialHospitals: hospitals,
              targetProfile: targetProfile,
              patientName: effectiveName,
              patientPhone: effectivePhone,
              onAppointmentBooked: onAppointmentBooked,
            ),
          ),
        );
      } else {
        await Navigator.pushNamed(
          context,
          AppRoutes.addAppointmentScreen,
          arguments: {
            if (effectiveName != null && effectiveName.isNotEmpty) 'patientName': effectiveName,
            if (effectivePhone != null && effectivePhone.isNotEmpty) 'patientPhone': effectivePhone,
          },
        );
      }
    } catch (_) {
      if (context.mounted) {
        await Navigator.pushNamed(
          context,
          AppRoutes.addAppointmentScreen,
          arguments: {
            if (effectiveName != null && effectiveName.isNotEmpty) 'patientName': effectiveName,
            if (effectivePhone != null && effectivePhone.isNotEmpty) 'patientPhone': effectivePhone,
          },
        );
      }
    }

    onAppointmentBooked?.call();
  }
}
