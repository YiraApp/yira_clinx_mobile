part of 'patient_profile_bloc.dart';

@immutable
abstract class PatientProfileState extends Equatable {
  const PatientProfileState();

  @override
  List<Object?> get props => [];
}

class PatientProfileInitial extends PatientProfileState {}

class PatientProfileLoading extends PatientProfileState {}

class PatientProfileLoaded extends PatientProfileState {
  final PatientProfileEntity patient;

  const PatientProfileLoaded(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientProfileError extends PatientProfileState {
  final String message;

  const PatientProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
