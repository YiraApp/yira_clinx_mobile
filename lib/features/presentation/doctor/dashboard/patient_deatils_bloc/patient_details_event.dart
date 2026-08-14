part of 'patient_details_bloc.dart';

@immutable
abstract class PatientDetailsEvent extends Equatable {
  const PatientDetailsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPatientScreenData extends PatientDetailsEvent {
  final String appointmentId;
  final String patientId;
  final String orgId;
  final String hospitalId;

  const LoadPatientScreenData({
    required this.appointmentId,
    required this.patientId,
    required this.orgId,
    required this.hospitalId,
  });

  @override
  List<Object?> get props => [appointmentId, patientId, orgId, hospitalId];
}
