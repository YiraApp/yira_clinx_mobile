
import 'package:equatable/equatable.dart';

class MedicalRecordEntity extends Equatable {
  final String visitType;
  final DateTime recordDate;
  final String chiefComplaint;
  final String symptoms;
  final String physicalExamination;
  final String bp;
  final String hr;
  final String temperature;
  final String weight;
  final String height;
  final String diagnosis;
  final String treatmentPlan;

  const MedicalRecordEntity({
    required this.visitType,
    required this.recordDate,
    required this.chiefComplaint,
    required this.symptoms,
    required this.physicalExamination,
    required this.bp,
    required this.hr,
    required this.temperature,
    required this.weight,
    required this.height,
    required this.diagnosis,
    required this.treatmentPlan,
  });

  @override
  List<Object?> get props => [
    visitType,
    recordDate,
    chiefComplaint,
    symptoms,
    physicalExamination,
    bp,
    hr,
    temperature,
    weight,
    height,
    diagnosis,
    treatmentPlan,
  ];
}