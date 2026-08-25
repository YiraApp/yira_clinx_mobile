import '../../../domain/entities/dashboard/dashboard_patient_details_entity.dart';

class DashBoardPatientDetailsModel extends DashBoardPatientDetailsEntity {
  const DashBoardPatientDetailsModel({
    super.status,
    super.message,
    PatientDashboardDataModel? super.data,
  });

  factory DashBoardPatientDetailsModel.fromJson(Map<String, dynamic> json) {
    return DashBoardPatientDetailsModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? PatientDashboardDataModel.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': (data as PatientDashboardDataModel?)?.toJson(),
    };
  }
}

class PatientDashboardDataModel extends PatientDashboardDataEntity {
  const PatientDashboardDataModel({
    PatientInfoModel? super.patientInfo,
    ContactInformationModel? super.contactInformation,
    LatestVitalsModel? super.latestVitals,
    MedicalInformationModel? super.medicalInformation,
    InsuranceModel? super.insurance,
    NextAppointmentModel? super.nextAppointment,
  });

  factory PatientDashboardDataModel.fromJson(Map<String, dynamic> json) {
    return PatientDashboardDataModel(
      patientInfo: json['patient_info'] != null ? PatientInfoModel.fromJson(json['patient_info']) : null,
      contactInformation: json['contact_information'] != null ? ContactInformationModel.fromJson(json['contact_information']) : null,
      latestVitals: json['latest_vitals'] != null ? LatestVitalsModel.fromJson(json['latest_vitals']) : null,
      medicalInformation: json['medical_information'] != null ? MedicalInformationModel.fromJson(json['medical_information']) : null,
      insurance: json['insurance'] != null ? InsuranceModel.fromJson(json['insurance']) : null,
      nextAppointment: json['next_appointment'] != null ? NextAppointmentModel.fromJson(json['next_appointment']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_info': (patientInfo as PatientInfoModel?)?.toJson(),
      'contact_information': (contactInformation as ContactInformationModel?)?.toJson(),
      'latest_vitals': (latestVitals as LatestVitalsModel?)?.toJson(),
      'medical_information': (medicalInformation as MedicalInformationModel?)?.toJson(),
      'insurance': (insurance as InsuranceModel?)?.toJson(),
      'next_appointment': (nextAppointment as NextAppointmentModel?)?.toJson(),
    };
  }
}

class NextAppointmentModel extends NextAppointmentEntity {
  const NextAppointmentModel({
    super.id,
    super.appointmentId,
    super.doctorName,
    super.doctorId,
    super.hospitalId,
    super.hospitalName,
    super.orgId,
    super.orgName,
    super.appointmentDate,
    super.formattedDate,
    super.startTime,
    super.formattedTime,
    super.consultationType,
    super.isTeleconsultation,
    super.reason,
    super.status,
    super.meetingUrl,
  });

  factory NextAppointmentModel.fromJson(Map<String, dynamic> json) {
    return NextAppointmentModel(
      id: json['id'],
      appointmentId: json['appointment_id']?.toString(),
      doctorName: json['doctor_name'],
      doctorId: json['doctor_id']?.toString(),
      hospitalId: json['hospital_id'],
      hospitalName: json['hospital_name'],
      orgId: json['org_id'],
      orgName: json['org_name'],
      appointmentDate: json['appointment_date'],
      formattedDate: json['formatted_date'],
      startTime: json['start_time'],
      formattedTime: json['formatted_time'],
      consultationType: json['consultation_type'],
      isTeleconsultation: json['is_teleconsultation'],
      reason: json['reason'],
      status: json['status'],
      meetingUrl: json['meeting_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'doctor_name': doctorName,
      'doctor_id': doctorId,
      'hospital_id': hospitalId,
      'hospital_name': hospitalName,
      'org_id': orgId,
      'org_name': orgName,
      'appointment_date': appointmentDate,
      'formatted_date': formattedDate,
      'start_time': startTime,
      'formatted_time': formattedTime,
      'consultation_type': consultationType,
      'is_teleconsultation': isTeleconsultation,
      'reason': reason,
      'status': status,
      'meeting_url': meetingUrl,
    };
  }
}

class PatientInfoModel extends PatientInfoEntity {
  const PatientInfoModel({
    super.patientId,
    super.appointmentId,
    super.name,
    super.age,
    super.gender,
    super.lastVisit,
  });

  factory PatientInfoModel.fromJson(Map<String, dynamic> json) {
    return PatientInfoModel(
      patientId: json['patient_id'],
      appointmentId: json['appointment_id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      lastVisit: json['last_visit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'name': name,
      'age': age,
      'gender': gender,
      'last_visit': lastVisit,
    };
  }
}

class ContactInformationModel extends ContactInformationEntity {
  const ContactInformationModel({super.phone, super.email, super.location});

  factory ContactInformationModel.fromJson(Map<String, dynamic> json) {
    return ContactInformationModel(
      phone: json['phone'],
      email: json['email'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'location': location,
    };
  }
}

class LatestVitalsModel extends LatestVitalsEntity {
  const LatestVitalsModel({
    VitalMeasurementModel? super.bloodPressure,
    VitalMeasurementModel? super.pulse,
    VitalMeasurementModel? super.temperature,
    VitalMeasurementModel? super.spo2,
    VitalMeasurementModel? super.weight,
    VitalMeasurementModel? super.height,
  });

  factory LatestVitalsModel.fromJson(Map<String, dynamic> json) {
    return LatestVitalsModel(
      bloodPressure: json['blood_pressure'] != null ? VitalMeasurementModel.fromJson(json['blood_pressure']) : null,
      pulse: json['pulse'] != null ? VitalMeasurementModel.fromJson(json['pulse']) : null,
      temperature: json['temperature'] != null ? VitalMeasurementModel.fromJson(json['temperature']) : null,
      spo2: json['spo2'] != null ? VitalMeasurementModel.fromJson(json['spo2']) : null,
      weight: json['weight'] != null ? VitalMeasurementModel.fromJson(json['weight']) : null,
      height: json['height'] != null ? VitalMeasurementModel.fromJson(json['height']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blood_pressure': (bloodPressure as VitalMeasurementModel?)?.toJson(),
      'pulse': (pulse as VitalMeasurementModel?)?.toJson(),
      'temperature': (temperature as VitalMeasurementModel?)?.toJson(),
      'spo2': (spo2 as VitalMeasurementModel?)?.toJson(),
      'weight': (weight as VitalMeasurementModel?)?.toJson(),
      'height': (height as VitalMeasurementModel?)?.toJson(),
    };
  }
}

class VitalMeasurementModel extends VitalMeasurementEntity {
  const VitalMeasurementModel({super.value, super.unit});

  factory VitalMeasurementModel.fromJson(Map<String, dynamic> json) {
    return VitalMeasurementModel(
      value: json['value'],
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
    };
  }
}

class MedicalInformationModel extends MedicalInformationEntity {
  const MedicalInformationModel({super.bloodGroup});

  factory MedicalInformationModel.fromJson(Map<String, dynamic> json) {
    return MedicalInformationModel(
      bloodGroup: json['blood_group'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blood_group': bloodGroup,
    };
  }
}

class InsuranceModel extends InsuranceEntity {
  const InsuranceModel({super.provider, super.policyNumber, super.validTill});

  factory InsuranceModel.fromJson(Map<String, dynamic> json) {
    return InsuranceModel(
      provider: json['provider'],
      policyNumber: json['policy_number'],
      validTill: json['valid_till'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'policy_number': policyNumber,
      'valid_till': validTill,
    };
  }
}