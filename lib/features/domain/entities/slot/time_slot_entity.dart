
import 'package:equatable/equatable.dart';

enum SlotStatus { available, booked, blocked }
enum AppointmentType { consult, review, regularCheckUp, followUp }

class TimeSlot extends Equatable {
  final String id;
  final String time;
  final String duration;
  final SlotStatus status;
  final String? patientName;
  final AppointmentType? type;
  final bool isVerified;
  final String? appointmentId;
  final String? reason;

  const TimeSlot({
    required this.id,
    required this.time,
    required this.duration,
    required this.status,
    this.patientName,
    this.type,
    this.isVerified = false,
    this.appointmentId,
    this.reason,
  });

  @override
  List<Object?> get props => [id, time, duration, status, patientName, type, isVerified, appointmentId, reason];
}