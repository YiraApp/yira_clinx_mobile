
import 'package:equatable/equatable.dart';

class MedicalRecordBriefEntity extends Equatable {
  final String id;
  final String title;
  final DateTime recordDate;
  final String doctorName;
  final String status;
  final String chiefComplaint;
  final String diagnosis;
  final String vitalsSummary;
  final String? symptoms;
  final String? physicalExamination;
  final String? treatmentPlan;
  final String? bloodPressure;
  final String? heartRate;
  final String? temperature;
  final String? weight;
  final String? height;

  const MedicalRecordBriefEntity({
    required this.id,
    required this.title,
    required this.recordDate,
    required this.doctorName,
    required this.status,
    required this.chiefComplaint,
    required this.diagnosis,
    required this.vitalsSummary,
    this.symptoms,
    this.physicalExamination,
    this.treatmentPlan,
    this.bloodPressure,
    this.heartRate,
    this.temperature,
    this.weight,
    this.height,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        recordDate,
        doctorName,
        status,
        chiefComplaint,
        diagnosis,
        vitalsSummary,
        symptoms,
        physicalExamination,
        treatmentPlan,
        bloodPressure,
        heartRate,
        temperature,
        weight,
        height,
      ];
}