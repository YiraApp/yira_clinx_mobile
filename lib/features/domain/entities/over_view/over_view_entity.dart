
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

  const DataEntity({
    this.contactInformation,
    this.medicalInformation,
    this.insurance,
    this.visitHistory,
    this.summary,
  });
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