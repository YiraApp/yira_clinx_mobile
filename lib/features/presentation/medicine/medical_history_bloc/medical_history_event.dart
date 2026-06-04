part of 'medical_history_bloc.dart';

@immutable
abstract class MedicalHistoryEvent {
  const MedicalHistoryEvent();
}

class LoadMedicalHistoryRecords extends MedicalHistoryEvent {}

class DeleteMedicalHistoryRecord extends MedicalHistoryEvent {
  final String recordId;
  const DeleteMedicalHistoryRecord(this.recordId);
}
