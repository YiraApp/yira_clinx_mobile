import '../../../domain/entities/over_view/over_view_entity.dart';

class PatientOverViewModel extends PatientOverViewEntity {
  const PatientOverViewModel({
    super.status,
    super.message,
    DataModel? super.data,
  });

  factory PatientOverViewModel.fromJson(Map<String, dynamic> json) {
    return PatientOverViewModel(
      status: json['status'] == true || json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] != null && json['data'] is Map
          ? DataModel.fromJson(Map<String, dynamic>.from(json['data'] as Map))
          : (json['result'] != null && json['result'] is Map
              ? DataModel.fromJson(Map<String, dynamic>.from(json['result'] as Map))
              : (json['payload'] != null && json['payload'] is Map
                  ? DataModel.fromJson(Map<String, dynamic>.from(json['payload'] as Map))
                  : null)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      if (data != null && data is DataModel) 'data': (data as DataModel).toJson(),
    };
  }
}

class DataModel extends DataEntity {
  const DataModel({
    ContactInformationModel? contactInformation,
    MedicalInformationModel? medicalInformation,
    InsuranceModel? insurance,
    VisitHistoryModel? visitHistory,
    super.summary,
    List<PatientAppointmentModel>? appointments,
    NextAppointmentModel? nextAppointment,
    List<NextAppointmentModel>? upcomingAppointments,
    LatestVitalsModel? latestVitals,
  }) : super(
    contactInformation: contactInformation,
    medicalInformation: medicalInformation,
    insurance: insurance,
    visitHistory: visitHistory,
    appointments: appointments,
    nextAppointment: nextAppointment,
    upcomingAppointments: upcomingAppointments,
    latestVitals: latestVitals,
  );

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      contactInformation: json['contact_information'] != null && json['contact_information'] is Map
          ? ContactInformationModel.fromJson(Map<String, dynamic>.from(json['contact_information'] as Map))
          : (json['contactInformation'] != null && json['contactInformation'] is Map
              ? ContactInformationModel.fromJson(Map<String, dynamic>.from(json['contactInformation'] as Map))
              : null),
      medicalInformation: json['medical_information'] != null && json['medical_information'] is Map
          ? MedicalInformationModel.fromJson(Map<String, dynamic>.from(json['medical_information'] as Map))
          : (json['medicalInformation'] != null && json['medicalInformation'] is Map
              ? MedicalInformationModel.fromJson(Map<String, dynamic>.from(json['medicalInformation'] as Map))
              : null),
      insurance: json['insurance'] != null && json['insurance'] is Map
          ? InsuranceModel.fromJson(Map<String, dynamic>.from(json['insurance'] as Map))
          : null,
      visitHistory: json['visit_history'] != null && json['visit_history'] is Map
          ? VisitHistoryModel.fromJson(Map<String, dynamic>.from(json['visit_history'] as Map))
          : (json['visitHistory'] != null && json['visitHistory'] is Map
              ? VisitHistoryModel.fromJson(Map<String, dynamic>.from(json['visitHistory'] as Map))
              : null),
      summary: json['summary']?.toString(),
      appointments: json['appointments'] is List
          ? (json['appointments'] as List)
              .whereType<Map>()
              .map((i) => PatientAppointmentModel.fromJson(Map<String, dynamic>.from(i)))
              .toList()
          : null,
      nextAppointment: json['next_appointment'] != null && json['next_appointment'] is Map
          ? NextAppointmentModel.fromJson(Map<String, dynamic>.from(json['next_appointment'] as Map))
          : (json['nextAppointment'] != null && json['nextAppointment'] is Map
              ? NextAppointmentModel.fromJson(Map<String, dynamic>.from(json['nextAppointment'] as Map))
              : null),
      upcomingAppointments: json['upcoming_appointments'] is List
          ? (json['upcoming_appointments'] as List)
              .whereType<Map>()
              .map((e) => NextAppointmentModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : (json['upcomingAppointments'] is List
              ? (json['upcomingAppointments'] as List)
                  .whereType<Map>()
                  .map((e) => NextAppointmentModel.fromJson(Map<String, dynamic>.from(e)))
                  .toList()
              : null),
      latestVitals: json['latest_vitals'] != null && json['latest_vitals'] is Map
          ? LatestVitalsModel.fromJson(Map<String, dynamic>.from(json['latest_vitals'] as Map))
          : (json['latestVitals'] != null && json['latestVitals'] is Map
              ? LatestVitalsModel.fromJson(Map<String, dynamic>.from(json['latestVitals'] as Map))
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (contactInformation != null && contactInformation is ContactInformationModel)
        'contact_information': (contactInformation as ContactInformationModel).toJson(),
      if (medicalInformation != null && medicalInformation is MedicalInformationModel)
        'medical_information': (medicalInformation as MedicalInformationModel).toJson(),
      if (insurance != null && insurance is InsuranceModel)
        'insurance': (insurance as InsuranceModel).toJson(),
      if (visitHistory != null && visitHistory is VisitHistoryModel)
        'visit_history': (visitHistory as VisitHistoryModel).toJson(),
      'summary': summary,
      if (appointments != null)
        'appointments': appointments
            ?.map((a) => a is PatientAppointmentModel ? a.toJson() : null)
            .whereType<Map<String, dynamic>>()
            .toList(),
      if (nextAppointment != null && nextAppointment is NextAppointmentModel)
        'next_appointment': (nextAppointment as NextAppointmentModel).toJson(),
      if (upcomingAppointments != null)
        'upcoming_appointments': upcomingAppointments
            ?.map((a) => a is NextAppointmentModel ? a.toJson() : null)
            .whereType<Map<String, dynamic>>()
            .toList(),
      if (latestVitals != null && latestVitals is LatestVitalsModel)
        'latest_vitals': (latestVitals as LatestVitalsModel).toJson(),
    };
  }
}

class PatientAppointmentModel extends PatientAppointmentEntity {
  const PatientAppointmentModel({
    required super.id,
    super.appointmentNumber,
    super.tokenNumber,
    super.appointmentDate,
    super.rawDate,
    super.startTime,
    super.endTime,
    super.duration,
    super.condition,
    super.chiefComplaint,
    super.reason,
    super.status,
    super.appointmentType,
    super.isTeleConsultation,
    super.meetingUrl,
    super.location,
    super.hospitalName,
    super.hospitalAddress,
    super.hospitalPhone,
    super.doctorId,
    super.doctorName,
    super.doctorEmail,
    super.doctorPhone,
    super.patientName,
    super.patientUserId,
    super.relation,
    super.isPrimary,
    super.notes,
    super.createdAt,
    super.createdBy,
    List<AppointmentPrescriptionModel> super.prescriptions = const [],
    List<AppointmentClinicalNoteModel> super.clinicalNotes = const [],
    List<AppointmentDocumentModel> super.documents = const [],
    List<AppointmentMedicalRecordModel> super.medicalRecords = const [],
  });

  factory PatientAppointmentModel.fromJson(Map<String, dynamic> json) {
    final isTele = json['is_tele_consultation'] == true ||
        json['isTeleConsultation'] == true ||
        json['is_tele_consultation'] == 1 ||
        json['is_tele_consultation']?.toString().toLowerCase() == 'true' ||
        (json['appointment_type'] ?? json['appointmentType'] ?? '').toString().toLowerCase().contains('tele') ||
        (json['appointment_type'] ?? json['appointmentType'] ?? '').toString().toLowerCase().contains('video');

    final pName = (json['patient_name'] ?? json['patientName'] ?? '').toString();
    final pUserId = (json['patient_user_id'] ?? json['patientUserId'] ?? json['userId'] ?? '').toString();
    final rel = (json['relation'] ?? 'Self').toString();
    final isPrim = json['is_primary'] == true || json['isPrimary'] == true || json['is_primary'] == 1;

    return PatientAppointmentModel(
      id: (json['id'] ?? json['appointmentId'] ?? json['appointment_id'] ?? '').toString(),
      appointmentNumber: (json['appointment_number'] ?? json['appointmentNumber'] ?? '').toString(),
      tokenNumber: (json['token_number'] ?? json['tokenNumber'] ?? '').toString(),
      appointmentDate: (json['appointment_date'] ?? json['appointmentDate'] ?? json['date'] ?? '').toString(),
      rawDate: json['raw_date'] ?? json['rawDate'] ?? json['appointmentDate'],
      startTime: (json['start_time'] ?? json['startTime'] ?? json['time'] ?? '').toString(),
      endTime: (json['end_time'] ?? json['endTime'] ?? '').toString(),
      duration: (json['duration'] ?? '15 mins').toString(),
      condition: (json['condition'] ?? json['chief_complaint'] ?? json['chiefComplaint'] ?? json['reason'] ?? 'General Consultation').toString(),
      chiefComplaint: (json['chief_complaint'] ?? json['chiefComplaint'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? 'Confirmed').toString(),
      appointmentType: (json['appointment_type'] ?? json['appointmentType'] ?? 'In-Clinic').toString(),
      isTeleConsultation: isTele,
      meetingUrl: (json['meeting_url'] ?? json['meetingUrl'] ?? json['videoCallUrl'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      hospitalName: (json['hospital_name'] ?? json['hospitalName'] ?? '').toString(),
      hospitalAddress: (json['hospital_address'] ?? json['hospitalAddress'] ?? '').toString(),
      hospitalPhone: (json['hospital_phone'] ?? json['hospitalPhone'] ?? '').toString(),
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '').toString(),
      doctorName: (json['doctor_name'] ?? json['doctorName'] ?? 'Doctor').toString(),
      doctorEmail: (json['doctor_email'] ?? json['doctorEmail'] ?? '').toString(),
      doctorPhone: (json['doctor_phone'] ?? json['doctorPhone'] ?? '').toString(),
      patientName: pName,
      patientUserId: pUserId,
      relation: rel,
      isPrimary: isPrim,
      notes: (json['notes'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      createdBy: (json['created_by'] ?? json['createdBy'] ?? '').toString(),
      prescriptions: json['prescriptions'] is List
          ? (json['prescriptions'] as List)
              .whereType<Map>()
              .map((p) => AppointmentPrescriptionModel.fromJson(Map<String, dynamic>.from(p)))
              .toList()
          : const [],
      clinicalNotes: json['clinical_notes'] is List
          ? (json['clinical_notes'] as List)
              .whereType<Map>()
              .map((n) => AppointmentClinicalNoteModel.fromJson(Map<String, dynamic>.from(n)))
              .toList()
          : (json['clinicalNotes'] is List
              ? (json['clinicalNotes'] as List)
                  .whereType<Map>()
                  .map((n) => AppointmentClinicalNoteModel.fromJson(Map<String, dynamic>.from(n)))
                  .toList()
              : const []),
      documents: json['documents'] is List
          ? (json['documents'] as List)
              .whereType<Map>()
              .map((d) => AppointmentDocumentModel.fromJson(Map<String, dynamic>.from(d)))
              .toList()
          : const [],
      medicalRecords: json['medical_records'] is List
          ? (json['medical_records'] as List)
              .whereType<Map>()
              .map((r) => AppointmentMedicalRecordModel.fromJson(Map<String, dynamic>.from(r)))
              .toList()
          : (json['medicalRecords'] is List
              ? (json['medicalRecords'] as List)
                  .whereType<Map>()
                  .map((r) => AppointmentMedicalRecordModel.fromJson(Map<String, dynamic>.from(r)))
                  .toList()
              : const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_number': appointmentNumber,
      'token_number': tokenNumber,
      'appointment_date': appointmentDate,
      'raw_date': rawDate,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'condition': condition,
      'chief_complaint': chiefComplaint,
      'reason': reason,
      'status': status,
      'appointment_type': appointmentType,
      'is_tele_consultation': isTeleConsultation,
      'meeting_url': meetingUrl,
      'location': location,
      'hospital_name': hospitalName,
      'hospital_address': hospitalAddress,
      'hospital_phone': hospitalPhone,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'doctor_email': doctorEmail,
      'doctor_phone': doctorPhone,
      'notes': notes,
      'created_at': createdAt,
      'created_by': createdBy,
      'prescriptions': prescriptions.map((p) => p is AppointmentPrescriptionModel ? p.toJson() : null).whereType<Map<String, dynamic>>().toList(),
      'clinical_notes': clinicalNotes.map((n) => n is AppointmentClinicalNoteModel ? n.toJson() : null).whereType<Map<String, dynamic>>().toList(),
      'documents': documents.map((d) => d is AppointmentDocumentModel ? d.toJson() : null).whereType<Map<String, dynamic>>().toList(),
      'medical_records': medicalRecords.map((r) => r is AppointmentMedicalRecordModel ? r.toJson() : null).whereType<Map<String, dynamic>>().toList(),
    };
  }
}

class AppointmentPrescriptionModel extends AppointmentPrescriptionEntity {
  const AppointmentPrescriptionModel({
    required super.id,
    super.date,
    super.notes,
    super.doctorName,
    List<AppointmentMedicationModel> super.medications = const [],
    List<AppointmentDiagnosisModel> super.diagnoses = const [],
  });

  factory AppointmentPrescriptionModel.fromJson(Map<String, dynamic> json) {
    return AppointmentPrescriptionModel(
      id: (json['id'] ?? '').toString(),
      date: (json['date'] ?? json['createdAt'] ?? '').toString(),
      notes: json['notes']?.toString() ?? '',
      doctorName: (json['doctor_name'] ?? json['doctorName'] ?? '').toString(),
      medications: json['medications'] is List
          ? (json['medications'] as List)
              .whereType<Map>()
              .map((m) => AppointmentMedicationModel.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      diagnoses: json['diagnoses'] is List
          ? (json['diagnoses'] as List)
              .whereType<Map>()
              .map((d) => AppointmentDiagnosisModel.fromJson(Map<String, dynamic>.from(d)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'notes': notes,
      'doctor_name': doctorName,
      'medications': medications.map((m) => m is AppointmentMedicationModel ? m.toJson() : null).whereType<Map<String, dynamic>>().toList(),
      'diagnoses': diagnoses.map((d) => d is AppointmentDiagnosisModel ? d.toJson() : null).whereType<Map<String, dynamic>>().toList(),
    };
  }
}

class AppointmentMedicationModel extends AppointmentMedicationEntity {
  const AppointmentMedicationModel({
    required super.id,
    super.name,
    super.dosage,
    super.frequency,
    super.duration,
    super.instructions,
  });

  factory AppointmentMedicationModel.fromJson(Map<String, dynamic> json) {
    return AppointmentMedicationModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['medication'] ?? '').toString(),
      dosage: (json['dosage'] ?? '').toString(),
      frequency: (json['frequency'] ?? json['frequencyType'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }
}

class AppointmentDiagnosisModel extends AppointmentDiagnosisEntity {
  const AppointmentDiagnosisModel({
    required super.id,
    super.name,
    super.icd10,
  });

  factory AppointmentDiagnosisModel.fromJson(Map<String, dynamic> json) {
    return AppointmentDiagnosisModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['diagnosis'] ?? '').toString(),
      icd10: (json['icd10'] ?? json['diagnosisConceptId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icd10': icd10,
    };
  }
}

class AppointmentClinicalNoteModel extends AppointmentClinicalNoteEntity {
  const AppointmentClinicalNoteModel({
    required super.id,
    super.notes,
    super.doctorName,
    super.createdAt,
  });

  factory AppointmentClinicalNoteModel.fromJson(Map<String, dynamic> json) {
    return AppointmentClinicalNoteModel(
      id: (json['id'] ?? '').toString(),
      notes: (json['notes'] ?? json['note'] ?? '').toString(),
      doctorName: (json['doctor_name'] ?? json['doctorName'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? json['date'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notes': notes,
      'doctor_name': doctorName,
      'created_at': createdAt,
    };
  }
}

class AppointmentDocumentModel extends AppointmentDocumentEntity {
  const AppointmentDocumentModel({
    required super.id,
    super.fileName,
    super.category,
    super.type,
    super.fileUrl,
    super.createdAt,
  });

  factory AppointmentDocumentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentDocumentModel(
      id: (json['id'] ?? '').toString(),
      fileName: (json['file_name'] ?? json['fileName'] ?? json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? json['fileUrl'] ?? json['url'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'category': category,
      'type': type,
      'file_url': fileUrl,
      'created_at': createdAt,
    };
  }
}

class AppointmentMedicalRecordModel extends AppointmentMedicalRecordEntity {
  const AppointmentMedicalRecordModel({
    required super.id,
    super.recordType,
    super.fileUrl,
    super.createdAt,
  });

  factory AppointmentMedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return AppointmentMedicalRecordModel(
      id: (json['id'] ?? '').toString(),
      recordType: (json['record_type'] ?? json['recordType'] ?? json['type'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? json['fileUrl'] ?? json['url'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': recordType,
      'file_url': fileUrl,
      'created_at': createdAt,
    };
  }
}

class ContactInformationModel extends ContactInformationEntity {
  const ContactInformationModel({
    super.phone,
    super.emailAddress,
    super.residentialAddress,
    EmergencyContactModel? super.emergencyContact,
  });

  factory ContactInformationModel.fromJson(Map<String, dynamic> json) {
    return ContactInformationModel(
      phone: json['phone']?.toString(),
      emailAddress: (json['email_address'] ?? json['emailAddress'] ?? json['email'])?.toString(),
      residentialAddress: (json['residential_address'] ?? json['residentialAddress'] ?? json['address'])?.toString(),
      emergencyContact: json['emergency_contact'] != null && json['emergency_contact'] is Map
          ? EmergencyContactModel.fromJson(Map<String, dynamic>.from(json['emergency_contact'] as Map))
          : (json['emergencyContact'] != null && json['emergencyContact'] is Map
              ? EmergencyContactModel.fromJson(Map<String, dynamic>.from(json['emergencyContact'] as Map))
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email_address': emailAddress,
      'residential_address': residentialAddress,
      if (emergencyContact != null && emergencyContact is EmergencyContactModel)
        'emergency_contact': (emergencyContact as EmergencyContactModel).toJson(),
    };
  }
}

class EmergencyContactModel extends EmergencyContactEntity {
  const EmergencyContactModel({super.name, super.phone});

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
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
    super.condition,
    super.allergies,
    super.bloodGroup,
    super.totalVisits,
  });

  factory MedicalInformationModel.fromJson(Map<String, dynamic> json) {
    return MedicalInformationModel(
      condition: json['condition']?.toString(),
      allergies: json['allergies']?.toString(),
      bloodGroup: (json['blood_group'] ?? json['bloodGroup'])?.toString(),
      totalVisits: json['total_visits'] is int
          ? json['total_visits'] as int
          : (json['totalVisits'] is int
              ? json['totalVisits'] as int
              : int.tryParse((json['total_visits'] ?? json['totalVisits'] ?? '').toString())),
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
  const InsuranceModel({super.policyName, super.policyNumber});

  factory InsuranceModel.fromJson(Map<String, dynamic> json) {
    return InsuranceModel(
      policyName: (json['policy_name'] ?? json['policyName'])?.toString(),
      policyNumber: (json['policy_number'] ?? json['policyNumber'])?.toString(),
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
    super.initialRegistration,
    super.lastCheckInVisit,
    super.nextScheduledAppointment,
  });

  factory VisitHistoryModel.fromJson(Map<String, dynamic> json) {
    return VisitHistoryModel(
      initialRegistration: (json['initial_registration'] ?? json['initialRegistration'])?.toString(),
      lastCheckInVisit: (json['last_check_in_visit'] ?? json['lastCheckInVisit'])?.toString(),
      nextScheduledAppointment: (json['next_scheduled_appointment'] ?? json['nextScheduledAppointment'])?.toString(),
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
      appointmentId: (json['appointment_id'] ?? json['appointmentId'] ?? json['id'])?.toString(),
      doctorName: (json['doctor_name'] ?? json['doctorName'])?.toString(),
      doctorId: (json['doctor_id'] ?? json['doctorId'])?.toString(),
      doctorSpecialty: (json['doctor_specialty'] ?? json['doctorSpecialty'])?.toString(),
      hospitalId: json['hospital_id'] is int
          ? json['hospital_id'] as int
          : (json['hospitalId'] is int
              ? json['hospitalId'] as int
              : int.tryParse((json['hospital_id'] ?? json['hospitalId'] ?? '').toString())),
      hospitalName: (json['hospital_name'] ?? json['hospitalName'])?.toString(),
      orgId: json['org_id'] is int
          ? json['org_id'] as int
          : (json['orgId'] is int
              ? json['orgId'] as int
              : int.tryParse((json['org_id'] ?? json['orgId'] ?? '').toString())),
      orgName: (json['org_name'] ?? json['orgName'])?.toString(),
      appointmentDate: (json['appointment_date'] ?? json['appointmentDate'])?.toString(),
      formattedDate: (json['formatted_date'] ?? json['formattedDate'])?.toString(),
      startTime: (json['start_time'] ?? json['startTime'])?.toString(),
      formattedTime: (json['formatted_time'] ?? json['formattedTime'])?.toString(),
      consultationType: (json['consultation_type'] ?? json['consultationType'])?.toString(),
      isTeleconsultation: json['is_teleconsultation'] == true ||
          json['isTeleconsultation'] == true ||
          json['is_tele_consultation'] == true ||
          json['isTeleConsultation'] == true,
      reason: json['reason']?.toString(),
      status: json['status']?.toString(),
      meetingUrl: (json['meeting_url'] ?? json['meetingUrl'] ?? json['videoCallUrl'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'doctor_name': doctorName,
      'doctor_id': doctorId,
      'doctor_specialty': doctorSpecialty,
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
      bloodPressure: VitalMeasurementModel.parse(
        json['blood_pressure'] ?? json['bloodPressure'] ?? json['bp'],
        defaultUnit: 'mmHg',
      ),
      pulse: VitalMeasurementModel.parse(
        json['pulse'] ?? json['heartRate'] ?? json['heart_rate'],
        defaultUnit: 'bpm',
      ),
      temperature: VitalMeasurementModel.parse(
        json['temperature'] ?? json['temp'],
        defaultUnit: '°F',
      ),
      spo2: VitalMeasurementModel.parse(
        json['spo2'] ?? json['spO2'] ?? json['oxygen'],
        defaultUnit: '%',
      ),
      weight: VitalMeasurementModel.parse(
        json['weight'],
        defaultUnit: 'kg',
      ),
      height: VitalMeasurementModel.parse(
        json['height'],
        defaultUnit: 'cm',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bloodPressure != null && bloodPressure is VitalMeasurementModel)
        'blood_pressure': (bloodPressure as VitalMeasurementModel).toJson(),
      if (pulse != null && pulse is VitalMeasurementModel)
        'pulse': (pulse as VitalMeasurementModel).toJson(),
      if (temperature != null && temperature is VitalMeasurementModel)
        'temperature': (temperature as VitalMeasurementModel).toJson(),
      if (spo2 != null && spo2 is VitalMeasurementModel)
        'spo2': (spo2 as VitalMeasurementModel).toJson(),
      if (weight != null && weight is VitalMeasurementModel)
        'weight': (weight as VitalMeasurementModel).toJson(),
      if (height != null && height is VitalMeasurementModel)
        'height': (height as VitalMeasurementModel).toJson(),
    };
  }
}

class VitalMeasurementModel extends VitalMeasurementEntity {
  const VitalMeasurementModel({super.value, super.unit});

  static VitalMeasurementModel? parse(dynamic raw, {String defaultUnit = ''}) {
    if (raw == null) return null;
    if (raw is Map) {
      final v = raw['value'] ?? raw['val'];
      final u = raw['unit'] ?? defaultUnit;
      if (v == null || v.toString().trim().isEmpty) return null;
      return VitalMeasurementModel(
        value: v.toString().trim(),
        unit: u?.toString().trim() ?? defaultUnit,
      );
    }
    final str = raw.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null' || str.toLowerCase() == 'none' || str.toLowerCase() == 'n/a') {
      return null;
    }
    return VitalMeasurementModel(
      value: str,
      unit: defaultUnit,
    );
  }

  factory VitalMeasurementModel.fromJson(Map<String, dynamic> json) {
    return VitalMeasurementModel(
      value: json['value']?.toString(),
      unit: json['unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
    };
  }
}