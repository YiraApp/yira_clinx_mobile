
import '../../../domain/entities/medicine/medical_record_entity.dart';


class MedicalRecordModel extends MedicalRecordEntity {
  const MedicalRecordModel({
    required super.visitType,
    required super.recordDate,
    required super.chiefComplaint,
    required super.symptoms,
    required super.physicalExamination,
    required super.bp,
    required super.hr,
    required super.temperature,
    required super.weight,
    required super.height,
    required super.diagnosis,
    required super.treatmentPlan,
  });

  Map<String, dynamic> toJson() {
    return {
      'visit_type': visitType,
      'record_date': recordDate.toIso8601String(),
      'chief_complaint': chiefComplaint,
      'symptoms': symptoms,
      'physical_examination': physicalExamination,
      'blood_pressure': bp,
      'heart_rate': hr,
      'temperature': temperature,
      'weight': weight,
      'height': height,
      'diagnosis': diagnosis,
      'treatment_plan': treatmentPlan,
    };
  }

  factory MedicalRecordModel.fromEntity(MedicalRecordEntity entity) {
    return MedicalRecordModel(
      visitType: entity.visitType,
      recordDate: entity.recordDate,
      chiefComplaint: entity.chiefComplaint,
      symptoms: entity.symptoms,
      physicalExamination: entity.physicalExamination,
      bp: entity.bp,
      hr: entity.hr,
      temperature: entity.temperature,
      weight: entity.weight,
      height: entity.height,
      diagnosis: entity.diagnosis,
      treatmentPlan: entity.treatmentPlan,
    );
  }
}