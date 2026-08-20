import 'package:equatable/equatable.dart';

abstract class PatientAccessConsentEvent extends Equatable {
  const PatientAccessConsentEvent();

  @override
  List<Object?> get props => [];
}

class CheckAccessStatusEvent extends PatientAccessConsentEvent {
  final String patientId;
  final String doctorId;

  const CheckAccessStatusEvent({
    required this.patientId,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [patientId, doctorId];
}

class RequestPatientAccessEvent extends PatientAccessConsentEvent {
  final String patientId;
  final String doctorId;
  final int? hospitalId;
  final String duration;
  final String? notes;

  const RequestPatientAccessEvent({
    required this.patientId,
    required this.doctorId,
    this.hospitalId,
    required this.duration,
    this.notes,
  });

  @override
  List<Object?> get props => [patientId, doctorId, hospitalId, duration, notes];
}

class LoadPatientConsentsEvent extends PatientAccessConsentEvent {
  final String patientId;

  const LoadPatientConsentsEvent({required this.patientId});

  @override
  List<Object?> get props => [patientId];
}

class RespondToConsentEvent extends PatientAccessConsentEvent {
  final int consentId;
  final String patientId;
  final String action; // 'APPROVE', 'REJECT', 'REVOKE'

  const RespondToConsentEvent({
    required this.consentId,
    required this.patientId,
    required this.action,
  });

  @override
  List<Object?> get props => [consentId, patientId, action];
}
