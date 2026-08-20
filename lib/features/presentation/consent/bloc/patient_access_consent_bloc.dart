import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/domain/repositories/consent/patient_access_consent_repo.dart';
import 'patient_access_consent_event.dart';
import 'patient_access_consent_state.dart';

class PatientAccessConsentBloc extends Bloc<PatientAccessConsentEvent, PatientAccessConsentState> {
  final PatientAccessConsentRepository _repository;

  PatientAccessConsentBloc(this._repository) : super(PatientAccessConsentInitial()) {
    on<CheckAccessStatusEvent>(_onCheckAccessStatus);
    on<RequestPatientAccessEvent>(_onRequestPatientAccess);
    on<LoadPatientConsentsEvent>(_onLoadPatientConsents);
    on<RespondToConsentEvent>(_onRespondToConsent);
  }

  Future<void> _onCheckAccessStatus(
    CheckAccessStatusEvent event,
    Emitter<PatientAccessConsentState> emit,
  ) async {
    emit(PatientAccessConsentLoading());
    try {
      final res = await _repository.checkAccess(
        patientId: event.patientId,
        doctorId: event.doctorId,
      );

      emit(DoctorAccessStatusLoaded(
        hasAccess: res.hasAccess,
        status: res.status,
        consent: res.consent,
        expiresAt: res.expiresAt,
        remainingMinutes: res.remainingMinutes,
        durationLabel: res.durationLabel,
      ));
    } catch (e) {
      emit(PatientAccessConsentError(message: e.toString()));
    }
  }

  Future<void> _onRequestPatientAccess(
    RequestPatientAccessEvent event,
    Emitter<PatientAccessConsentState> emit,
  ) async {
    emit(PatientAccessConsentLoading());
    try {
      final consent = await _repository.requestAccess(
        patientId: event.patientId,
        doctorId: event.doctorId,
        hospitalId: event.hospitalId,
        duration: event.duration,
        notes: event.notes,
      );

      emit(DoctorAccessStatusLoaded(
        hasAccess: false,
        status: 'PENDING',
        consent: consent,
        durationLabel: consent.durationLabel,
      ));
    } catch (e) {
      emit(PatientAccessConsentError(message: e.toString()));
    }
  }

  Future<void> _onLoadPatientConsents(
    LoadPatientConsentsEvent event,
    Emitter<PatientAccessConsentState> emit,
  ) async {
    emit(PatientAccessConsentLoading());
    try {
      final consents = await _repository.getPatientConsents(
        patientId: event.patientId,
      );
      emit(PatientConsentsListLoaded(consents: consents));
    } catch (e) {
      emit(PatientAccessConsentError(message: e.toString()));
    }
  }

  Future<void> _onRespondToConsent(
    RespondToConsentEvent event,
    Emitter<PatientAccessConsentState> emit,
  ) async {
    try {
      await _repository.respondToConsent(
        consentId: event.consentId,
        action: event.action,
      );
      // Refresh list
      final consents = await _repository.getPatientConsents(
        patientId: event.patientId,
      );
      emit(PatientConsentsListLoaded(consents: consents));
    } catch (e) {
      emit(PatientAccessConsentError(message: e.toString()));
    }
  }
}
