part of 'medical_history_bloc.dart';

@immutable
abstract class MedicalHistoryEvent extends Equatable {
  const MedicalHistoryEvent();
}

class LoadMedicalHistoryRecords extends MedicalHistoryEvent {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  const LoadMedicalHistoryRecords({
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
  });

  @override
  List<Object?> get props => [patientId, appointmentId, hospitalId, orgId];
}

class DeleteMedicalHistoryRecord extends MedicalHistoryEvent {
  final String recordId;
  const DeleteMedicalHistoryRecord(this.recordId);
  @override
  List<Object?> get props => [recordId];
}

class AddMedicalRecordNavEvent extends MedicalHistoryEvent {
  @override
  List<Object?> get props => [];
}

class SingleMedicineDetailsNavEvent extends MedicalHistoryEvent {
  final String recordId;
  final MedicalRecordBriefEntity? record;

  const SingleMedicineDetailsNavEvent({required this.recordId, this.record});

  @override
  List<Object?> get props => [recordId, record];
}