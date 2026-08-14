import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../../../domain/repositories/patient_profile/patient_profile_repo.dart';

class PatientRepositoryImpl implements PatientRepository {

  PatientRepositoryImpl();

  @override
  Future<PatientProfileEntity> getPatientProfile(String patientId, {String? patientName}) async {
    try {
      final String nameToUse = (patientName != null && patientName.trim().isNotEmpty)
          ? patientName.trim()
          : (patientId == '3456' ? 'Teja Ch' : 'Patient $patientId');

      final String emailName = nameToUse.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      return PatientProfileEntity(
        id: patientId,
        name: nameToUse,
        dob: '2006-02-18',
        gender: 'Male',
        bloodGroup: 'B+',
        phone: '6303012453',
        email: '${emailName.isNotEmpty ? emailName : "patient"}@gmail.com',
        address: 'Sandhya techno 1, Hyderabad, pin code - 500081',
        emergencyContactName: 'Rajesh',
        emergencyContactPhone: '9908875796',
        condition: 'Severe persistent hand pain in the right distal radius extending up through the metacarpal joints.',
        allergies: 'None reported',
        totalVisits: 2,
        registrationDate: 'May 26, 2026',
        lastVisitDate: 'Aug 10, 2026',
        nextAppointment: null,
        summary: 'Severe persistent hand pain in the right distal radius extending up through the metacarpal joints.',
        policyName: 'Star Health Premier',
        policyNumber: 'ST-99482-XYZ',
      );
    } catch (e) {
      throw Exception('Failed to load patient profile: $e');
    }
  }
}