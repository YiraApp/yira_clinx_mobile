part of 'appointment_bloc.dart';

@immutable
abstract class AppointmentEvent {}

class LoadAppointmentsEvent extends AppointmentEvent {
  final String? status;
  final String? search;
  final String? date;
  final String? dateFrom;
  final String? dateTo;

  LoadAppointmentsEvent({this.status, this.search, this.date, this.dateFrom, this.dateTo});
}

class OnAddAppointmentEvent extends AppointmentEvent {}

class SubmitBookAppointmentEvent extends AppointmentEvent {
  final String patientName;
  final String phoneNumber;
  final String? doctorId;
  final int? hospitalId;
  final int? orgId;
  final String? patientUserId;
  final String? parentUserId;
  final String? relation;
  final bool? isPrimary;
  final String? patientEmail;
  final String? gender;
  final String? dob;
  final String? appointmentDate;
  final String? startTime;
  final String? reason;
  final String? appointmentType;
  final bool? isTeleConsultation;
  final int? parentAppointmentId;
  final List<String>? treatmentPlanIds;
  final List<Map<String, dynamic>>? customTreatmentPlans;
  final double? discountAmount;
  final bool? includeConsultationFee;
  final double? consultationFee;

  SubmitBookAppointmentEvent({
    required this.patientName,
    required this.phoneNumber,
    this.doctorId,
    this.hospitalId,
    this.orgId,
    this.patientUserId,
    this.parentUserId,
    this.relation,
    this.isPrimary,
    this.patientEmail,
    this.gender,
    this.dob,
    this.appointmentDate,
    this.startTime,
    this.reason,
    this.appointmentType,
    this.isTeleConsultation,
    this.parentAppointmentId,
    this.treatmentPlanIds,
    this.customTreatmentPlans,
    this.discountAmount,
    this.includeConsultationFee,
    this.consultationFee,
  });
}

class UpdateAppointmentStatusEvent extends AppointmentEvent {
  final String appointmentId;
  final String status;

  UpdateAppointmentStatusEvent({
    required this.appointmentId,
    required this.status,
  });
}