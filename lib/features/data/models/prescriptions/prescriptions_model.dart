

import '../../../domain/entities/prescriptions/prescription_entity.dart';
import '../../../domain/entities/prescriptions/prescription_item.dart';

class PrescriptionModel extends PrescriptionEntity {
  const PrescriptionModel({
    required super.patientId,
    required super.diagnoses,
    required super.medications,
    required super.additionalNotes,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      patientId: json['patient_id'] as String? ?? '',
      diagnoses: (json['diagnoses'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      medications: (json['medications'] as List<dynamic>?)
          ?.map((e) => MedicationItemModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      additionalNotes: json['additional_notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'diagnoses': diagnoses,
      'medications': medications.map((m) => MedicationItemModel.fromEntity(m).toJson()).toList(),
      'additional_notes': additionalNotes,
    };
  }
}

class MedicationItemModel extends MedicationItem {
  const MedicationItemModel({
    required super.id,
    required super.name,
    super.dosage,
    super.frequency,
    super.duration,
    super.route,
  });

  factory MedicationItemModel.fromJson(Map<String, dynamic> json) {
    return MedicationItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      duration: json['duration'] as String?,
      route: json['route'] as String?,
    );
  }

  factory MedicationItemModel.fromEntity(MedicationItem entity) {
    return MedicationItemModel(
      id: entity.id,
      name: entity.name,
      dosage: entity.dosage,
      frequency: entity.frequency,
      duration: entity.duration,
      route: entity.route,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'route': route,
    };
  }
}