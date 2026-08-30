class PatientOverViewEntity {
  final bool? status;
  final String? message;
  final DataEntity? data;

  const PatientOverViewEntity({
    this.status,
    this.message,
    this.data,
  });
}

class DataEntity {
  final ContactInformationEntity? contactInformation;
  final MedicalInformationEntity? medicalInformation;
  final InsuranceEntity? insurance;
  final VisitHistoryEntity? visitHistory;
  final String? summary;
  final List<PatientAppointmentEntity>? appointments;
  final NextAppointmentEntity? nextAppointment;
  final List<NextAppointmentEntity>? upcomingAppointments;
  final LatestVitalsEntity? latestVitals;

  const DataEntity({
    this.contactInformation,
    this.medicalInformation,
    this.insurance,
    this.visitHistory,
    this.summary,
    this.appointments,
    this.nextAppointment,
    this.upcomingAppointments,
    this.latestVitals,
  });
}

class PatientAppointmentEntity {
  final String id;
  final String appointmentNumber;
  final String tokenNumber;
  final String appointmentDate;
  final dynamic rawDate;
  final String startTime;
  final String endTime;
  final String duration;
  final String condition;
  final String chiefComplaint;
  final String reason;
  final String status;
  final String appointmentType;
  final bool isTeleConsultation;
  final String meetingUrl;
  final String location;
  final String hospitalName;
  final String hospitalAddress;
  final String hospitalPhone;
  final String doctorId;
  final String doctorName;
  final String doctorEmail;
  final String doctorPhone;
  final String patientName;
  final String patientUserId;
  final String relation;
  final bool isPrimary;
  final String notes;
  final String createdAt;
  final String createdBy;
  final List<AppointmentPrescriptionEntity> prescriptions;
  final List<AppointmentClinicalNoteEntity> clinicalNotes;
  final List<AppointmentDocumentEntity> documents;
  final List<AppointmentMedicalRecordEntity> medicalRecords;

  const PatientAppointmentEntity({
    required this.id,
    this.appointmentNumber = '',
    this.tokenNumber = '',
    this.appointmentDate = '',
    this.rawDate,
    this.startTime = '',
    this.endTime = '',
    this.duration = '15 mins',
    this.condition = '',
    this.chiefComplaint = '',
    this.reason = '',
    this.status = 'Confirmed',
    this.appointmentType = 'In-Clinic',
    this.isTeleConsultation = false,
    this.meetingUrl = '',
    this.location = '',
    this.hospitalName = '',
    this.hospitalAddress = '',
    this.hospitalPhone = '',
    this.doctorId = '',
    this.doctorName = '',
    this.doctorEmail = '',
    this.doctorPhone = '',
    this.patientName = '',
    this.patientUserId = '',
    this.relation = 'Self',
    this.isPrimary = true,
    this.notes = '',
    this.createdAt = '',
    this.createdBy = '',
    this.prescriptions = const [],
    this.clinicalNotes = const [],
    this.documents = const [],
    this.medicalRecords = const [],
  });
}

class AppointmentPrescriptionEntity {
  final String id;
  final String date;
  final String notes;
  final String doctorName;
  final List<AppointmentMedicationEntity> medications;
  final List<AppointmentDiagnosisEntity> diagnoses;

  const AppointmentPrescriptionEntity({
    required this.id,
    this.date = '',
    this.notes = '',
    this.doctorName = '',
    this.medications = const [],
    this.diagnoses = const [],
  });
}

class AppointmentMedicationEntity {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  const AppointmentMedicationEntity({
    required this.id,
    this.name = '',
    this.dosage = '',
    this.frequency = '',
    this.duration = '',
    this.instructions = '',
  });
}

class AppointmentDiagnosisEntity {
  final String id;
  final String name;
  final String icd10;

  const AppointmentDiagnosisEntity({
    required this.id,
    this.name = '',
    this.icd10 = '',
  });
}

class AppointmentClinicalNoteEntity {
  final String id;
  final String notes;
  final String doctorName;
  final String createdAt;

  const AppointmentClinicalNoteEntity({
    required this.id,
    this.notes = '',
    this.doctorName = '',
    this.createdAt = '',
  });
}

class AppointmentDocumentEntity {
  final String id;
  final String fileName;
  final String category;
  final String type;
  final String fileUrl;
  final String createdAt;

  const AppointmentDocumentEntity({
    required this.id,
    this.fileName = '',
    this.category = '',
    this.type = '',
    this.fileUrl = '',
    this.createdAt = '',
  });
}

class AppointmentMedicalRecordEntity {
  final String id;
  final String recordType;
  final String fileUrl;
  final String createdAt;

  const AppointmentMedicalRecordEntity({
    required this.id,
    this.recordType = '',
    this.fileUrl = '',
    this.createdAt = '',
  });
}

class NextAppointmentEntity {
  final dynamic id;
  final String? appointmentId;
  final String? doctorName;
  final String? doctorId;
  final String? doctorSpecialty;
  final int? hospitalId;
  final String? hospitalName;
  final int? orgId;
  final String? orgName;
  final String? appointmentDate;
  final String? formattedDate;
  final String? startTime;
  final String? formattedTime;
  final String? consultationType;
  final bool? isTeleconsultation;
  final String? reason;
  final String? status;
  final String? meetingUrl;

  const NextAppointmentEntity({
    this.id,
    this.appointmentId,
    this.doctorName,
    this.doctorId,
    this.doctorSpecialty,
    this.hospitalId,
    this.hospitalName,
    this.orgId,
    this.orgName,
    this.appointmentDate,
    this.formattedDate,
    this.startTime,
    this.formattedTime,
    this.consultationType,
    this.isTeleconsultation,
    this.reason,
    this.status,
    this.meetingUrl,
  });
}

class LatestVitalsEntity {
  final VitalMeasurementEntity? bloodPressure;
  final VitalMeasurementEntity? pulse;
  final VitalMeasurementEntity? temperature;
  final VitalMeasurementEntity? spo2;
  final VitalMeasurementEntity? weight;
  final VitalMeasurementEntity? height;

  const LatestVitalsEntity({
    this.bloodPressure,
    this.pulse,
    this.temperature,
    this.spo2,
    this.weight,
    this.height,
  });
}

class VitalMeasurementEntity {
  final String? value;
  final String? unit;

  const VitalMeasurementEntity({this.value, this.unit});
}

class ContactInformationEntity {
  final String? phone;
  final String? emailAddress;
  final String? residentialAddress;
  final EmergencyContactEntity? emergencyContact;

  const ContactInformationEntity({
    this.phone,
    this.emailAddress,
    this.residentialAddress,
    this.emergencyContact,
  });
}

class EmergencyContactEntity {
  final String? name;
  final String? phone;

  const EmergencyContactEntity({this.name, this.phone});
}

class MedicalInformationEntity {
  final String? condition;
  final String? allergies;
  final String? bloodGroup;
  final int? totalVisits;

  const MedicalInformationEntity({
    this.condition,
    this.allergies,
    this.bloodGroup,
    this.totalVisits,
  });
}

class InsuranceEntity {
  final String? policyName;
  final String? policyNumber;

  const InsuranceEntity({this.policyName, this.policyNumber});
}

class VisitHistoryEntity {
  final String? initialRegistration;
  final String? lastCheckInVisit;
  final String? nextScheduledAppointment;

  const VisitHistoryEntity({
    this.initialRegistration,
    this.lastCheckInVisit,
    this.nextScheduledAppointment,
  });
}