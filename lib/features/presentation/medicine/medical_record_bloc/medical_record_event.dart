part of 'medical_record_bloc.dart';

@immutable
abstract class MedicalRecordEvent {
  const MedicalRecordEvent();
}

/// Triggered when the doctor modifies the date field using the bottom picker sheet
class ChangeSelectedDateEvent extends MedicalRecordEvent {
  final DateTime selectedDate;

  const ChangeSelectedDateEvent(this.selectedDate);
}

/// Form entry completion submittal matching entity creation expectations
class SaveMedicalRecordEvent extends MedicalRecordEvent {
  final String visitType;
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

  const SaveMedicalRecordEvent({
    required this.visitType,
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
}
