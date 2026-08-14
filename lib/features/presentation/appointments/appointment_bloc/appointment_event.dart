part of 'appointment_bloc.dart';

@immutable
abstract class AppointmentEvent {}

class LoadAppointmentsEvent extends AppointmentEvent {
  final String? status;
  final String? search;

  LoadAppointmentsEvent({this.status, this.search});
}

class OnAddAppointmentEvent extends AppointmentEvent {}

class SubmitBookAppointmentEvent extends AppointmentEvent {
  final String patientName;
  final String phoneNumber;
  final String? gender;
  final String? dob;
  final String? appointmentDate;
  final String? startTime;
  final String? reason;
  final String? appointmentType;
  final bool? isTeleConsultation;

  SubmitBookAppointmentEvent({
    required this.patientName,
    required this.phoneNumber,
    this.gender,
    this.dob,
    this.appointmentDate,
    this.startTime,
    this.reason,
    this.appointmentType,
    this.isTeleConsultation,
  });
}