part of 'patient_over_view_bloc.dart';

@immutable
abstract class PatientOverViewEvent extends Equatable {}

class LoadPatientData extends PatientOverViewEvent {
  final String patientId;
  final String? orgId;
  final String? hospitalId;

  LoadPatientData(
    this.patientId, {
    this.orgId,
    this.hospitalId,
  });

  @override
  List<Object?> get props => [patientId, orgId, hospitalId];
}
