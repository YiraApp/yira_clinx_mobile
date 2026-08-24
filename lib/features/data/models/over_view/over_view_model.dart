import '../../../domain/entities/over_view/over_view_entity.dart';

class PatientOverViewModel extends PatientOverViewEntity {
  const PatientOverViewModel({
    bool? status,
    String? message,
    DataModel? data,
  }) : super(status: status, message: message, data: data);

  factory PatientOverViewModel.fromJson(Map<String, dynamic> json) {
    return PatientOverViewModel(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? DataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      if (data != null) 'data': (data as DataModel).toJson(),
    };
  }
}

class DataModel extends DataEntity {
  const DataModel({
    ContactInformationModel? contactInformation,
    MedicalInformationModel? medicalInformation,
    InsuranceModel? insurance,
    VisitHistoryModel? visitHistory,
    String? summary,
    NextAppointmentModel? nextAppointment,
    List<NextAppointmentModel>? upcomingAppointments,
    LatestVitalsModel? latestVitals,
  }) : super(
    contactInformation: contactInformation,
    medicalInformation: medicalInformation,
    insurance: insurance,
    visitHistory: visitHistory,
    summary: summary,
    nextAppointment: nextAppointment,
    upcomingAppointments: upcomingAppointments,
    latestVitals: latestVitals,
  );

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      contactInformation: json['contact_information'] != null
          ? ContactInformationModel.fromJson(json['contact_information'] as Map<String, dynamic>)
          : null,
      medicalInformation: json['medical_information'] != null
          ? MedicalInformationModel.fromJson(json['medical_information'] as Map<String, dynamic>)
          : null,
      insurance: json['insurance'] != null
          ? InsuranceModel.fromJson(json['insurance'] as Map<String, dynamic>)
          : null,
      visitHistory: json['visit_history'] != null
          ? VisitHistoryModel.fromJson(json['visit_history'] as Map<String, dynamic>)
          : null,
      summary: json['summary'] as String?,
      nextAppointment: json['next_appointment'] != null
          ? NextAppointmentModel.fromJson(json['next_appointment'] as Map<String, dynamic>)
          : null,
      upcomingAppointments: json['upcoming_appointments'] != null
          ? (json['upcoming_appointments'] as List)
              .map((e) => NextAppointmentModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      latestVitals: json['latest_vitals'] != null
          ? LatestVitalsModel.fromJson(json['latest_vitals'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (contactInformation != null) 'contact_information': (contactInformation as ContactInformationModel).toJson(),
      if (medicalInformation != null) 'medical_information': (medicalInformation as MedicalInformationModel).toJson(),
      if (insurance != null) 'insurance': (insurance as InsuranceModel).toJson(),
      if (visitHistory != null) 'visit_history': (visitHistory as VisitHistoryModel).toJson(),
      'summary': summary,
    };
  }
}

class ContactInformationModel extends ContactInformationEntity {
  const ContactInformationModel({
    String? phone,
    String? emailAddress,
    String? residentialAddress,
    EmergencyContactModel? emergencyContact,
  }) : super(
    phone: phone,
    emailAddress: emailAddress,
    residentialAddress: residentialAddress,
    emergencyContact: emergencyContact,
  );

  factory ContactInformationModel.fromJson(Map<String, dynamic> json) {
    return ContactInformationModel(
      phone: json['phone'] as String?,
      emailAddress: json['email_address'] as String?,
      residentialAddress: json['residential_address'] as String?,
      emergencyContact: json['emergency_contact'] != null
          ? EmergencyContactModel.fromJson(json['emergency_contact'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email_address': emailAddress,
      'residential_address': residentialAddress,
      if (emergencyContact != null) 'emergency_contact': (emergencyContact as EmergencyContactModel).toJson(),
    };
  }
}

class EmergencyContactModel extends EmergencyContactEntity {
  const EmergencyContactModel({String? name, String? phone}) : super(name: name, phone: phone);

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}

class MedicalInformationModel extends MedicalInformationEntity {
  const MedicalInformationModel({
    String? condition,
    String? allergies,
    String? bloodGroup,
    int? totalVisits,
  }) : super(
    condition: condition,
    allergies: allergies,
    bloodGroup: bloodGroup,
    totalVisits: totalVisits,
  );

  factory MedicalInformationModel.fromJson(Map<String, dynamic> json) {
    return MedicalInformationModel(
      condition: json['condition'] as String?,
      allergies: json['allergies'] as String?,
      bloodGroup: json['blood_group'] as String?,
      totalVisits: json['total_visits'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'allergies': allergies,
      'blood_group': bloodGroup,
      'total_visits': totalVisits,
    };
  }
}

class InsuranceModel extends InsuranceEntity {
  const InsuranceModel({String? policyName, String? policyNumber})
      : super(policyName: policyName, policyNumber: policyNumber);

  factory InsuranceModel.fromJson(Map<String, dynamic> json) {
    return InsuranceModel(
      policyName: json['policy_name'] as String?,
      policyNumber: json['policy_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policy_name': policyName,
      'policy_number': policyNumber,
    };
  }
}

class VisitHistoryModel extends VisitHistoryEntity {
  const VisitHistoryModel({
    String? initialRegistration,
    String? lastCheckInVisit,
    String? nextScheduledAppointment,
  }) : super(
    initialRegistration: initialRegistration,
    lastCheckInVisit: lastCheckInVisit,
    nextScheduledAppointment: nextScheduledAppointment,
  );

  factory VisitHistoryModel.fromJson(Map<String, dynamic> json) {
    return VisitHistoryModel(
      initialRegistration: json['initial_registration'] as String?,
      lastCheckInVisit: json['last_check_in_visit'] as String?,
      nextScheduledAppointment: json['next_scheduled_appointment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'initial_registration': initialRegistration,
      'last_check_in_visit': lastCheckInVisit,
      'next_scheduled_appointment': nextScheduledAppointment,
    };
  }
}

class NextAppointmentModel extends NextAppointmentEntity {
  const NextAppointmentModel({
    super.id,
    super.appointmentId,
    super.doctorName,
    super.doctorId,
    super.doctorSpecialty,
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
      doctorSpecialty: json['doctor_specialty']?.toString(),
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
}

class LatestVitalsModel extends LatestVitalsEntity {
  const LatestVitalsModel({
    VitalMeasurementModel? bloodPressure,
    VitalMeasurementModel? pulse,
    VitalMeasurementModel? temperature,
    VitalMeasurementModel? spo2,
    VitalMeasurementModel? weight,
    VitalMeasurementModel? height,
  }) : super(
    bloodPressure: bloodPressure,
    pulse: pulse,
    temperature: temperature,
    spo2: spo2,
    weight: weight,
    height: height,
  );

  factory LatestVitalsModel.fromJson(Map<String, dynamic> json) {
    return LatestVitalsModel(
      bloodPressure: json['blood_pressure'] != null ? VitalMeasurementModel.fromJson(json['blood_pressure'] as Map<String, dynamic>) : null,
      pulse: json['pulse'] != null ? VitalMeasurementModel.fromJson(json['pulse'] as Map<String, dynamic>) : null,
      temperature: json['temperature'] != null ? VitalMeasurementModel.fromJson(json['temperature'] as Map<String, dynamic>) : null,
      spo2: json['spo2'] != null ? VitalMeasurementModel.fromJson(json['spo2'] as Map<String, dynamic>) : null,
      weight: json['weight'] != null ? VitalMeasurementModel.fromJson(json['weight'] as Map<String, dynamic>) : null,
      height: json['height'] != null ? VitalMeasurementModel.fromJson(json['height'] as Map<String, dynamic>) : null,
    );
  }
}

class VitalMeasurementModel extends VitalMeasurementEntity {
  const VitalMeasurementModel({super.value, super.unit});

  factory VitalMeasurementModel.fromJson(Map<String, dynamic> json) {
    return VitalMeasurementModel(
      value: json['value']?.toString(),
      unit: json['unit']?.toString(),
    );
  }
}