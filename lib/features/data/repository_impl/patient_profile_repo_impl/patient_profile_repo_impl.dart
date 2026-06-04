import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../../../domain/repositories/patient_profile/patient_profile_repo.dart';

class PatientRepositoryImpl implements PatientRepository {

  PatientRepositoryImpl();

  @override
  Future<PatientProfileEntity> getPatientProfile(String patientId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      return const PatientProfileEntity(
        id: '3456',
        name: 'Teja Ch',
        dob: '2006-02-18',
        gender: 'Male', // Explicit gender field value
        bloodGroup: 'B+',
        phone: '6303012453',
        email: 'teja@gmail.com',
        address: 'Sandhya techno 1, Hyderabad, pin code - 500081',
        emergencyContactName: 'Rajesh',
        emergencyContactPhone: '9908875796',
        condition: 'Severe persistent hand pain in the right distal radius extending up through the metacarpal joints.',
        allergies: 'illness',
        totalVisits: 0,
        registrationDate: 'May 26, 2026',
        lastVisitDate: 'May 26, 2026',
        nextAppointment: null,
        summary: 'Severe persistent hand pain in the right distal radius extending up through the metacarpal joints.',
        // New Policy Mock Data
        policyName: 'Star Health Premier',
        policyNumber: 'ST-99482-XYZ',
      );
    } catch (e) {
      throw Exception('Failed to load mock patient profile: $e');
    }
  }
}