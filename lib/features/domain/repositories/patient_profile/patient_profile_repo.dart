
import '../../entities/patient_profile/patient_profile_entity.dart';

abstract class PatientRepository {
  Future<PatientProfileEntity> getPatientProfile(String patientId, {String? patientName});
}