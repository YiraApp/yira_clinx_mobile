part of 'patient_details_bloc.dart';

@immutable
abstract class PatientDetailsState extends Equatable {
  final DashBoardPatientDetailsEntity? patientData;
  final DashBoardPatientDetailsClinicalNotesEntity? clinicalNotesData;

  const PatientDetailsState({this.patientData, this.clinicalNotesData});
  @override
  List<Object?> get props => [patientData, clinicalNotesData];
}

class PatientDetailsInitial extends PatientDetailsState {}
class PatientDetailsLoading extends PatientDetailsState {
  const PatientDetailsLoading({super.patientData, super.clinicalNotesData});
}
class PatientDetailsLoaded extends PatientDetailsState {
  const PatientDetailsLoaded({required super.patientData, required super.clinicalNotesData});
}
class PatientDetailsError extends PatientDetailsState {
  final String message;
  const PatientDetailsError({required this.message, super.patientData, super.clinicalNotesData});
  @override
  List<Object?> get props => [message, patientData, clinicalNotesData];
}
