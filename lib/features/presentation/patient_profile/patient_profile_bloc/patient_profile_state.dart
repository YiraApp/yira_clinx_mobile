part of 'patient_profile_bloc.dart';

@immutable
abstract class PatientProfileState extends Equatable {
  const PatientProfileState();

  @override
  List<Object?> get props => [];
}

class PatientProfileInitial extends PatientProfileState {}

class PatientProfileLoading extends PatientProfileState {}


class PatientProfileError extends PatientProfileState {
  final String message;

  const PatientProfileError(this.message);

  @override
  List<Object?> get props => [message];
}


class PatientProfileLoaded extends PatientProfileState {
  final PatientProfileEntity patient;
  final int activeTabIndex;

  const PatientProfileLoaded({
    required this.patient,
    this.activeTabIndex = 0,
  });

  PatientProfileLoaded copyWith({
    PatientProfileEntity? patient,
    int? activeTabIndex,
  }) {
    return PatientProfileLoaded(
      patient: patient ?? this.patient,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }

  @override
  List<Object?> get props => [patient, activeTabIndex];
}