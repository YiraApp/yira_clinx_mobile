import 'package:yiraclinics/features/domain/entities/consent/patient_access_consent_entity.dart';

class PatientAccessConsentModel extends PatientAccessConsentEntity {
  const PatientAccessConsentModel({
    super.id,
    super.patientId,
    super.doctorId,
    super.doctorName,
    super.doctorPhoto,
    super.doctorEmail,
    super.doctorPhone,
    super.specialty,
    super.qualification,
    super.hospitalId,
    super.hospitalName,
    super.duration,
    super.durationLabel,
    super.durationMinutes,
    super.status,
    super.requestedAt,
    super.approvedAt,
    super.expiresAt,
    super.remainingMinutes,
    super.notes,
  });

  factory PatientAccessConsentModel.fromJson(Map<String, dynamic> json) {
    return PatientAccessConsentModel(
      id: json['id'] is int ? json['id'] : (json['Id'] is int ? json['Id'] : null),
      patientId: json['patientId']?.toString() ?? json['PatientId']?.toString(),
      doctorId: json['doctorId']?.toString() ?? json['DoctorId']?.toString(),
      doctorName: json['doctorName']?.toString(),
      doctorPhoto: json['doctorPhoto']?.toString() ?? json['imagePath']?.toString(),
      doctorEmail: json['doctorEmail']?.toString(),
      doctorPhone: json['doctorPhone']?.toString(),
      specialty: json['specialty']?.toString(),
      qualification: json['qualification']?.toString(),
      hospitalId: json['hospitalId'] is int
          ? json['hospitalId']
          : (json['HospitalId'] is int ? json['HospitalId'] : null),
      hospitalName: json['hospitalName']?.toString(),
      duration: json['duration']?.toString() ?? json['Duration']?.toString() ?? '1_DAY',
      durationLabel: json['durationLabel']?.toString(),
      durationMinutes: json['durationMinutes'] is int
          ? json['durationMinutes']
          : (json['DurationMinutes'] is int ? json['DurationMinutes'] : 1440),
      status: json['status']?.toString() ?? json['Status']?.toString() ?? 'PENDING',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : (json['RequestedAt'] != null ? DateTime.tryParse(json['RequestedAt'].toString()) : null),
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'].toString())
          : (json['ApprovedAt'] != null ? DateTime.tryParse(json['ApprovedAt'].toString()) : null),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : (json['ExpiresAt'] != null ? DateTime.tryParse(json['ExpiresAt'].toString()) : null),
      remainingMinutes: json['remainingMinutes'] is int ? json['remainingMinutes'] : null,
      notes: json['notes']?.toString() ?? json['Notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorPhoto': doctorPhoto,
      'specialty': specialty,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'duration': duration,
      'durationLabel': durationLabel,
      'durationMinutes': durationMinutes,
      'status': status,
      'requestedAt': requestedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'remainingMinutes': remainingMinutes,
      'notes': notes,
    };
  }
}

class ConsentAccessCheckModel extends ConsentAccessCheckEntity {
  const ConsentAccessCheckModel({
    required super.hasAccess,
    required super.status,
    super.consent,
    super.expiresAt,
    super.remainingMinutes,
    super.durationLabel,
  });

  factory ConsentAccessCheckModel.fromJson(Map<String, dynamic> json) {
    return ConsentAccessCheckModel(
      hasAccess: json['hasAccess'] == true,
      status: json['status']?.toString() ?? 'NO_REQUEST',
      consent: json['consent'] != null
          ? PatientAccessConsentModel.fromJson(Map<String, dynamic>.from(json['consent']))
          : null,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
      remainingMinutes: json['remainingMinutes'] is int ? json['remainingMinutes'] : null,
      durationLabel: json['durationLabel']?.toString(),
    );
  }
}
