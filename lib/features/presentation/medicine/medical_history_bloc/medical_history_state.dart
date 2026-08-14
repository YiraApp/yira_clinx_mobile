part of 'medical_history_bloc.dart';

@immutable
abstract class MedicalHistoryState {
  const MedicalHistoryState();
}


class MedicalHistoryInitial extends MedicalHistoryState with EquatableMixin {
  @override
  List<Object?> get props => [];
}

class MedicalHistoryLoading extends MedicalHistoryState with EquatableMixin {
  @override
  List<Object?> get props => [];
}

class MedicalHistoryLoaded extends MedicalHistoryState with EquatableMixin {
  final List<MedicalRecordBriefEntity> records;
  const MedicalHistoryLoaded(this.records);

  @override
  List<Object?> get props => [records];
}

class MedicalHistoryError extends MedicalHistoryState with EquatableMixin {
  final String message;
  const MedicalHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class AddMedicalRecordNavState extends MedicalHistoryState {}

class SingleMedicineDetailsNavState extends MedicalHistoryState {
  final String recordId;
  final MedicalRecordBriefEntity? record;
  const SingleMedicineDetailsNavState({required this.recordId, this.record});
}