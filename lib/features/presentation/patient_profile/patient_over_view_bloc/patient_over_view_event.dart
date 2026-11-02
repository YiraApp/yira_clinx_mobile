part of 'patient_over_view_bloc.dart';

@immutable
abstract class PatientOverViewEvent extends Equatable {}

class LoadPatientData extends PatientOverViewEvent {
  final String patientId;
  final String? orgId;
  final String? hospitalId;

  /// Refresh in the background: keep showing the current data, no loader.
  final bool silent;

  LoadPatientData(
    this.patientId, {
    this.orgId,
    this.hospitalId,
    this.silent = false,
  });

  @override
  List<Object?> get props => [patientId, orgId, hospitalId, silent];
}
