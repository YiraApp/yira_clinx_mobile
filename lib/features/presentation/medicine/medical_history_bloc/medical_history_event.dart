part of 'medical_history_bloc.dart';

@immutable
abstract class MedicalHistoryEvent extends Equatable {
  const MedicalHistoryEvent();
}

class LoadMedicalHistoryRecords extends MedicalHistoryEvent {
  @override
  List<Object?> get props => [];
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
  const SingleMedicineDetailsNavEvent({required this.recordId});

  @override
  List<Object?> get props => [recordId];
}