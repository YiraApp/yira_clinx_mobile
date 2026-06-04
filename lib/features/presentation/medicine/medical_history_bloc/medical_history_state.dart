part of 'medical_history_bloc.dart';

@immutable
abstract class MedicalHistoryState {
  const MedicalHistoryState();
}

class MedicalHistoryInitial extends MedicalHistoryState {}
class MedicalHistoryLoading extends MedicalHistoryState {}
class MedicalHistoryLoaded extends MedicalHistoryState {
  final List<MedicalRecordBriefEntity> records;
  const MedicalHistoryLoaded(this.records);
}
class MedicalHistoryError extends MedicalHistoryState {
  final String message;
  const MedicalHistoryError(this.message);
}