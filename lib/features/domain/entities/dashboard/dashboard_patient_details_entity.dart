
class DashBoardPatientDetailsEntity {
  final bool? status;
  final String? message;
  final PatientDashboardDataEntity? data;

  const DashBoardPatientDetailsEntity({this.status, this.message, this.data});
}

class PatientDashboardDataEntity {
  final PatientInfoEntity? patientInfo;
  final ContactInformationEntity? contactInformation;
  final LatestVitalsEntity? latestVitals;
  final MedicalInformationEntity? medicalInformation;
  final InsuranceEntity? insurance;

  const PatientDashboardDataEntity({
    this.patientInfo,
    this.contactInformation,
    this.latestVitals,
    this.medicalInformation,
    this.insurance,
  });
}

class PatientInfoEntity {
  final String? patientId;
  final String? appointmentId;
  final String? name;
  final String? age;
  final String? gender;
  final String? lastVisit;

  const PatientInfoEntity({
    this.patientId,
    this.appointmentId,
    this.name,
    this.age,
    this.gender,
    this.lastVisit,
  });
}

class ContactInformationEntity {
  final String? phone;
  final String? email;
  final String? location;

  const ContactInformationEntity({this.phone, this.email, this.location});
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

class MedicalInformationEntity {
  final String? bloodGroup;

  const MedicalInformationEntity({this.bloodGroup});
}

class InsuranceEntity {
  final String? provider;
  final String? policyNumber;
  final String? validTill;

  const InsuranceEntity({this.provider, this.policyNumber, this.validTill});
}