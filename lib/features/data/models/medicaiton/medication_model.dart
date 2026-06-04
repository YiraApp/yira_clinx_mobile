import 'package:yiraclinics/features/domain/entities/medication/medication_entity.dart';


class MedicationSummaryModel extends MedicationEntity {
  const MedicationSummaryModel({
    required super.totalPrescriptions,
    required super.activeMeds,
    required super.totalMedications,
    required super.needRefill,
  });

  factory MedicationSummaryModel.fromJson(Map<String, dynamic> json) {
    return MedicationSummaryModel(
      totalPrescriptions: json['total_prescriptions'] ?? 0,
      activeMeds: json['active_meds'] ?? 0,
      totalMedications: json['total_medications'] ?? 0,
      needRefill: json['need_refill'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_prescriptions': totalPrescriptions,
      'active_meds': activeMeds,
      'total_medications': totalMedications,
      'need_refill': needRefill,
    };
  }
}