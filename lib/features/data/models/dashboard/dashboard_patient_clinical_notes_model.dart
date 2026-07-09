import '../../../domain/entities/dashboard/dashboard_patient_clinical_notes_entity.dart';

class DashBoardPatientDetailsClinicalNotesModel extends DashBoardPatientDetailsClinicalNotesEntity {
  const DashBoardPatientDetailsClinicalNotesModel({
    super.status,
    super.message,
    ClinicalNotesDataModel? super.data,
  });

  factory DashBoardPatientDetailsClinicalNotesModel.fromJson(Map<String, dynamic> json) {
    return DashBoardPatientDetailsClinicalNotesModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? ClinicalNotesDataModel.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': (data as ClinicalNotesDataModel?)?.toJson(),
    };
  }
}

class ClinicalNotesDataModel extends ClinicalNotesDataEntity {
  const ClinicalNotesDataModel({
    List<ClinicalNotesModel>? super.clinicalNotes,
  });

  factory ClinicalNotesDataModel.fromJson(Map<String, dynamic> json) {
    return ClinicalNotesDataModel(
      clinicalNotes: json['clinical_notes'] != null
          ? (json['clinical_notes'] as List)
          .map((v) => ClinicalNotesModel.fromJson(v))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clinical_notes': clinicalNotes?.map((v) => (v as ClinicalNotesModel).toJson()).toList(),
    };
  }
}

class ClinicalNotesModel extends ClinicalNotesEntity {
  const ClinicalNotesModel({
    super.id,
    super.doctorName,
    super.date,
    super.note,
  });

  factory ClinicalNotesModel.fromJson(Map<String, dynamic> json) {
    return ClinicalNotesModel(
      id: json['id'],
      doctorName: json['doctor_name'],
      date: json['date'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_name': doctorName,
      'date': date,
      'note': note,
    };
  }
}