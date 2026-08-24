
class PatientOverViewEntity {
  final bool? status;
  final String? message;
  final DataEntity? data;

  const PatientOverViewEntity({this.status, this.message, this.data});
}

class DataEntity {
  final ContactInformationEntity? contactInformation;
  final MedicalInformationEntity? medicalInformation;
  final InsuranceEntity? insurance;
  final VisitHistoryEntity? visitHistory;
  final String? summary;
  final NextAppointmentEntity? nextAppointment;
  final List<NextAppointmentEntity>? upcomingAppointments;
  final LatestVitalsEntity? latestVitals;

  const DataEntity({
    this.contactInformation,
    this.medicalInformation,
    this.insurance,
    this.visitHistory,
    this.summary,
    this.nextAppointment,
    this.upcomingAppointments,
    this.latestVitals,
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