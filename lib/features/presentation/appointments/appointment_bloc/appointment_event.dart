part of 'appointment_bloc.dart';

@immutable
abstract class AppointmentEvent {}
class LoadAppointmentsEvent extends AppointmentEvent {}
class OnAddAppointmentEvent extends AppointmentEvent {

}