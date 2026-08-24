import '../../../domain/entities/over_view/over_view_entity.dart';

class PatientOverViewModel extends PatientOverViewEntity {
  const PatientOverViewModel({
    super.status,
    super.message,
    DataModel? super.data,
  });

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
    ContactInformationModel? super.contactInformation,
    MedicalInformationModel? super.medicalInformation,
    InsuranceModel? super.insurance,
    VisitHistoryModel? super.visitHistory,
    super.summary,
    List<PatientAppointmentModel>? super.appointments,
  });

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
      appointments: json['appointments'] != null
          ? (json['appointments'] as List)
              .map((i) => PatientAppointmentModel.fromJson(i as Map<String, dynamic>))
              .toList()
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
      if (appointments != null)
        'appointments': appointments?.map((a) => (a as PatientAppointmentModel).toJson()).toList(),
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
    super.notes,
    super.createdAt,
    super.createdBy,
    List<AppointmentPrescriptionModel> super.prescriptions = const [],
    List<AppointmentClinicalNoteModel> super.clinicalNotes = const [],
    List<AppointmentDocumentModel> super.documents = const [],
    List<AppointmentMedicalRecordModel> super.medicalRecords = const [],
  });

  factory PatientAppointmentModel.fromJson(Map<String, dynamic> json) {
    return PatientAppointmentModel(
      id: json['id'] != null ? json['id'].toString() : '',
      appointmentNumber: json['appointment_number']?.toString() ?? '',
      tokenNumber: json['token_number']?.toString() ?? '',
      appointmentDate: json['appointment_date']?.toString() ?? '',
      rawDate: json['raw_date'],
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '15 mins',
      condition: json['condition']?.toString() ?? json['chief_complaint']?.toString() ?? 'General Consultation',
      chiefComplaint: json['chief_complaint']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Confirmed',
      appointmentType: json['appointment_type']?.toString() ?? 'In-Clinic',
      isTeleConsultation: json['is_tele_consultation'] == true,
      meetingUrl: json['meeting_url']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      hospitalName: json['hospital_name']?.toString() ?? '',
      hospitalAddress: json['hospital_address']?.toString() ?? '',
      hospitalPhone: json['hospital_phone']?.toString() ?? '',
      doctorId: json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
      doctorEmail: json['doctor_email']?.toString() ?? '',
      doctorPhone: json['doctor_phone']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      prescriptions: json['prescriptions'] != null
          ? (json['prescriptions'] as List)
              .map((p) => AppointmentPrescriptionModel.fromJson(p as Map<String, dynamic>))
              .toList()
          : const [],
      clinicalNotes: json['clinical_notes'] != null
          ? (json['clinical_notes'] as List)
              .map((n) => AppointmentClinicalNoteModel.fromJson(n as Map<String, dynamic>))
              .toList()
          : const [],
      documents: json['documents'] != null
          ? (json['documents'] as List)
              .map((d) => AppointmentDocumentModel.fromJson(d as Map<String, dynamic>))
              .toList()
          : const [],
      medicalRecords: json['medical_records'] != null
          ? (json['medical_records'] as List)
              .map((r) => AppointmentMedicalRecordModel.fromJson(r as Map<String, dynamic>))
              .toList()
          : const [],
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
      'prescriptions': prescriptions.map((p) => (p as AppointmentPrescriptionModel).toJson()).toList(),
      'clinical_notes': clinicalNotes.map((n) => (n as AppointmentClinicalNoteModel).toJson()).toList(),
      'documents': documents.map((d) => (d as AppointmentDocumentModel).toJson()).toList(),
      'medical_records': medicalRecords.map((r) => (r as AppointmentMedicalRecordModel).toJson()).toList(),
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
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
      medications: json['medications'] != null
          ? (json['medications'] as List)
              .map((m) => AppointmentMedicationModel.fromJson(m as Map<String, dynamic>))
              .toList()
          : const [],
      diagnoses: json['diagnoses'] != null
          ? (json['diagnoses'] as List)
              .map((d) => AppointmentDiagnosisModel.fromJson(d as Map<String, dynamic>))
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
      'medications': medications.map((m) => (m as AppointmentMedicationModel).toJson()).toList(),
      'diagnoses': diagnoses.map((d) => (d as AppointmentDiagnosisModel).toJson()).toList(),
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      instructions: json['instructions']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icd10: json['icd10']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
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
      id: json['id']?.toString() ?? '',
      recordType: json['record_type']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
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
  const EmergencyContactModel({super.name, super.phone});

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
    super.condition,
    super.allergies,
    super.bloodGroup,
    super.totalVisits,
  });

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
  const InsuranceModel({super.policyName, super.policyNumber});

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
    super.initialRegistration,
    super.lastCheckInVisit,
    super.nextScheduledAppointment,
  });

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