import 'package:flutter/foundation.dart' show immutable;

@immutable
class ClinxStorageKeys {

  const ClinxStorageKeys._();

  static const String doctorProfile = 'clinx_doc_profile_v1';
  static const String activeAppointments = 'clinx_active_appointments_v1';
  static const String patientQueue = 'clinx_patient_queue_v1';
  static const String medicalReportsConfig = 'clinx_medical_reports_cfg_v1';
  static const String clinicSettings = 'clinx_settings_v1';
  static const String appVersionInfo = 'app_version_info';
}