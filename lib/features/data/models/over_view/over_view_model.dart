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
  }) : super(
    contactInformation: contactInformation,
    medicalInformation: medicalInformation,
    insurance: insurance,
    visitHistory: visitHistory,
    summary: summary,
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