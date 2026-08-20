import 'package:equatable/equatable.dart';
import 'package:yiraclinics/features/domain/entities/consent/patient_access_consent_entity.dart';

abstract class PatientAccessConsentState extends Equatable {
  const PatientAccessConsentState();

  @override
  List<Object?> get props => [];
}

class PatientAccessConsentInitial extends PatientAccessConsentState {}

class PatientAccessConsentLoading extends PatientAccessConsentState {}

class DoctorAccessStatusLoaded extends PatientAccessConsentState {
  final bool hasAccess;
  final String status;
  final PatientAccessConsentEntity? consent;
  final DateTime? expiresAt;
  final int? remainingMinutes;
  final String? durationLabel;

  const DoctorAccessStatusLoaded({
    required this.hasAccess,
    required this.status,
    this.consent,
    this.expiresAt,
    this.remainingMinutes,
    this.durationLabel,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED' && hasAccess;
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isExpired => status.toUpperCase() == 'EXPIRED';
  bool get isNoRequest => status.toUpperCase() == 'NO_REQUEST';

  @override
  List<Object?> get props => [hasAccess, status, consent, expiresAt, remainingMinutes, durationLabel];
}

class PatientConsentsListLoaded extends PatientAccessConsentState {
  final List<PatientAccessConsentEntity> consents;

  const PatientConsentsListLoaded({required this.consents});

  List<PatientAccessConsentEntity> get pendingConsents =>
      consents.where((c) => c.status?.toUpperCase() == 'PENDING').toList();

  List<PatientAccessConsentEntity> get activeConsents =>
      consents.where((c) => c.status?.toUpperCase() == 'APPROVED').toList();

  List<PatientAccessConsentEntity> get historyConsents =>
      consents.where((c) => c.status?.toUpperCase() != 'PENDING' && c.status?.toUpperCase() != 'APPROVED').toList();

  @override
  List<Object?> get props => [consents];
}

class PatientAccessConsentError extends PatientAccessConsentState {
  final String message;

  const PatientAccessConsentError({required this.message});

  @override
  List<Object?> get props => [message];
}
