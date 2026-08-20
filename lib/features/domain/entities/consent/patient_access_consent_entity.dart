class PatientAccessConsentEntity {
  final int? id;
  final String? patientId;
  final String? doctorId;
  final String? doctorName;
  final String? doctorPhoto;
  final String? doctorEmail;
  final String? doctorPhone;
  final String? specialty;
  final String? qualification;
  final int? hospitalId;
  final String? hospitalName;
  final String? duration;
  final String? durationLabel;
  final int? durationMinutes;
  final String? status;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? expiresAt;
  final int? remainingMinutes;
  final String? notes;

  const PatientAccessConsentEntity({
    this.id,
    this.patientId,
    this.doctorId,
    this.doctorName,
    this.doctorPhoto,
    this.doctorEmail,
    this.doctorPhone,
    this.specialty,
    this.qualification,
    this.hospitalId,
    this.hospitalName,
    this.duration,
    this.durationLabel,
    this.durationMinutes,
    this.status,
    this.requestedAt,
    this.approvedAt,
    this.expiresAt,
    this.remainingMinutes,
    this.notes,
  });

  bool get isPending => status?.toUpperCase() == 'PENDING';
  bool get isApproved => status?.toUpperCase() == 'APPROVED';
  bool get isRejected => status?.toUpperCase() == 'REJECTED';
  bool get isExpired => status?.toUpperCase() == 'EXPIRED';
  bool get isRevoked => status?.toUpperCase() == 'REVOKED';
}

class ConsentAccessCheckEntity {
  final bool hasAccess;
  final String status;
  final PatientAccessConsentEntity? consent;
  final DateTime? expiresAt;
  final int? remainingMinutes;
  final String? durationLabel;

  const ConsentAccessCheckEntity({
    required this.hasAccess,
    required this.status,
    this.consent,
    this.expiresAt,
    this.remainingMinutes,
    this.durationLabel,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED' && hasAccess;
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isExpired => status.toUpperCase() == 'EXPIRED';
  bool get isNoRequest => status.toUpperCase() == 'NO_REQUEST';
}
