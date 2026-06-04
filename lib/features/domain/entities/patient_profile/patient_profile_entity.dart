class PatientProfileEntity {
  final String id;
  final String name;
  final String dob;
  final String gender;
  final String bloodGroup;
  final String phone;
  final String email;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String condition;
  final String allergies;
  final int totalVisits;
  final String registrationDate;
  final String lastVisitDate;
  final String? nextAppointment;
  final String summary;
  // Added Insurance fields
  final String? policyName;
  final String? policyNumber;

  const PatientProfileEntity({
    required this.id,
    required this.name,
    required this.dob,
    required this.gender,
    required this.bloodGroup,
    required this.phone,
    required this.email,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.condition,
    required this.allergies,
    required this.totalVisits,
    required this.registrationDate,
    required this.lastVisitDate,
    this.nextAppointment,
    required this.summary,
    this.policyName,
    this.policyNumber,
  });
}