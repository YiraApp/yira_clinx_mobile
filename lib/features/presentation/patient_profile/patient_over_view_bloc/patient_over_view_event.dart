part of 'patient_over_view_bloc.dart';

@immutable
abstract class PatientOverViewEvent extends Equatable {}

class LoadPatientData extends PatientOverViewEvent{
  final String patientId;

  LoadPatientData(this.patientId);
  @override
  List<Object?> get props => [patientId];
}
