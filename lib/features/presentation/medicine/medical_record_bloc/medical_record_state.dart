part of 'medical_record_bloc.dart';

@immutable
abstract class MedicalRecordState {
  final DateTime selectedDate;

  const MedicalRecordState({required this.selectedDate});
}

/// Initial form configuration state
class MedicalRecordInitial extends MedicalRecordState {
  MedicalRecordInitial({DateTime? initialDate})
      : super(selectedDate: initialDate ?? DateTime.now());
}

/// Processing submittals out to downstream repository data layer streams
class MedicalRecordLoading extends MedicalRecordState {
  const MedicalRecordLoading({required super.selectedDate});
}

/// Processing completed cleanly
class MedicalRecordSuccess extends MedicalRecordState {
  const MedicalRecordSuccess({required super.selectedDate});
}

/// Fallback or network system level validations failures
class MedicalRecordFailure extends MedicalRecordState {
  final String errorMessage;

  const MedicalRecordFailure(this.errorMessage, {required super.selectedDate});
}

/// State variant managing runtime mutation of form selections
class MedicalRecordFormUpdated extends MedicalRecordState {
  const MedicalRecordFormUpdated({required super.selectedDate});
}