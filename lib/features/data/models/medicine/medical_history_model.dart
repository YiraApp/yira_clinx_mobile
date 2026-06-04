
import '../../../domain/entities/medicine/medical_history_entity.dart';

class MedicalRecordBriefModel extends MedicalRecordBriefEntity {
  const MedicalRecordBriefModel({
    required super.id,
    required super.title,
    required super.recordDate,
    required super.doctorName,
    required super.status,
    required super.chiefComplaint,
    required super.diagnosis,
    required super.vitalsSummary,
  });

  factory MedicalRecordBriefModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordBriefModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'consultation',
      recordDate: DateTime.parse(json['record_date']),
      doctorName: json['doctor_name'] ?? '',
      status: json['status'] ?? 'COMPLETED',
      chiefComplaint: json['chief_complaint'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      vitalsSummary: json['vitals_summary'] ?? '',
    );
  }
}