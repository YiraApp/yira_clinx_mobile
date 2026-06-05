part of 'medical_history_bloc.dart';

@immutable
abstract class MedicalHistoryState extends Equatable {
  const MedicalHistoryState();
}

class MedicalHistoryInitial extends MedicalHistoryState {
  @override
  List<Object?> get props => [];
}
class MedicalHistoryLoading extends MedicalHistoryState {
  @override
  List<Object?> get props => [];
}
class AddMedicalRecordNavState extends MedicalHistoryState {
  @override
  List<Object?> get props => [];
}
class MedicalHistoryLoaded extends MedicalHistoryState {
  final List<MedicalRecordBriefEntity> records;
  const MedicalHistoryLoaded(this.records);
  @override
  List<Object?> get props => [records];
}
class MedicalHistoryError extends MedicalHistoryState {
  final String message;
  const MedicalHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
class SingleMedicineDetailsNavState extends MedicalHistoryState {
  @override
  List<Object?> get props => [];
}
