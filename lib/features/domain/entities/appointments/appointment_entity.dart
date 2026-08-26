
import 'package:equatable/equatable.dart';

enum AppointmentStatus { confirmed, paymentPending, pendingInfo }
enum AppointmentType { inClinic, videoCall }

class Appointment {
  final String id;
  final String tokenNumber;
  final String time;
  final String duration;
  final String patientName;
  final String phoneNumber;
  final AppointmentType type;
  final String category;
  final AppointmentStatus status;
  final String statusRaw;
  final String? patientStatus;
  final String? patientUserId;
  final String? doctorName;
  final String? relation;
  final bool? isPrimary;
  final int? orgId;
  final int? hospitalId;
  final String? hospitalName;
  final String? organizationName;
  final String? reason;
  final String? meetingUrl;

  const Appointment({
    required this.id,
    required this.tokenNumber,
    required this.time,
    required this.duration,
    required this.patientName,
    required this.phoneNumber,
    required this.type,
    required this.category,
    required this.status,
    this.statusRaw = '',
    this.patientStatus,
    this.patientUserId,
    this.doctorName = 'Doctor',
    this.relation = 'Self',
    this.isPrimary = true,
    this.orgId,
    this.hospitalId,
    this.hospitalName,
    this.organizationName,
    this.reason,
    this.meetingUrl,
  });
}


class AppointmentEntity extends Equatable {
  final String id;
  final String? patientName;
  final AppointmentType type;
  final String? reason;          // Maps to appointment.reason
  final String? diagnosis;       // Maps to recentLog.diagnosis
  final String? appointmentTime; // Maps to appointment.appointmentTime (e.g., "10:30 AM")
  final String? appointmentDate; // Maps to recentLog.appointmentDate (e.g., "24 May 2026")

  const AppointmentEntity({
    required this.id,
    this.patientName,
    required this.type,
    this.reason,
    this.diagnosis,
    this.appointmentTime,
    this.appointmentDate,
  });

  @override
  List<Object?> get props => [
    id,
    patientName,
    type,
    reason,
    diagnosis,
    appointmentTime,
    appointmentDate,
  ];
}