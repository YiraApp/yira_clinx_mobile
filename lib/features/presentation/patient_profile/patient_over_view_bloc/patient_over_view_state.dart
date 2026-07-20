part of 'patient_over_view_bloc.dart';

@immutable
sealed class PatientOverViewState extends Equatable {}

final class PatientOverViewInitial extends PatientOverViewState {
  @override
  List<Object?> get props => [];
}

class LoadPatientDataState extends PatientOverViewState{
  final PatientOverViewEntity patientOverViewEntity;

  LoadPatientDataState(this.patientOverViewEntity);
  @override
  List<Object?> get props => [patientOverViewEntity];
}
class LoadingPatientViewDetails extends PatientOverViewState {
  @override
  // TODO: implement props
  List<Object?> get props => [];
}
class LoadPatientDataFailureState extends PatientOverViewState{
  final String error;

  LoadPatientDataFailureState(this.error);
  @override
  List<Object?> get props => [error];
}
