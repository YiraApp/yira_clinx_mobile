part of 'patient_details_bloc.dart';

@immutable
abstract class PatientDetailsEvent extends Equatable {
  const PatientDetailsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPatientScreenData extends PatientDetailsEvent {
  final String appointmentId;
  const LoadPatientScreenData({required this.appointmentId});
  @override
  List<Object?> get props => [appointmentId];
}
