part of 'patient_profile_bloc.dart';

@immutable
abstract class PatientProfileEvent extends Equatable {
  const PatientProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadPatientProfile extends PatientProfileEvent {
  final String patientId;
  final String? patientName;

  const LoadPatientProfile(this.patientId, {this.patientName});

  @override
  List<Object?> get props => [patientId, patientName];
}

class TabChanged extends PatientProfileEvent {
  final int activeTabIndex;
  const TabChanged(this.activeTabIndex);

  @override
  List<Object> get props => [activeTabIndex];
}