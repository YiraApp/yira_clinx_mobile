import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../../../domain/repositories/patient_profile/patient_profile_repo.dart';

part 'patient_profile_event.dart';
part 'patient_profile_state.dart';

class PatientProfileBloc extends Bloc<PatientProfileEvent, PatientProfileState> {
  final PatientRepository repository;

  PatientProfileBloc({required this.repository}) : super(PatientProfileInitial()) {
    on<LoadPatientProfile>(_onLoadPatientProfile);
  }

  Future<void> _onLoadPatientProfile(
      LoadPatientProfile event,
      Emitter<PatientProfileState> emit,
      ) async {
    emit(PatientProfileLoading());
    try {
      // Direct call to your mock repository without dartz .fold()
      final patient = await repository.getPatientProfile(event.patientId);

      emit(PatientProfileLoaded(patient));
    } catch (e) {
      // Catches the mock repository Exception and propagates it to your UI state
      emit(PatientProfileError(e.toString()));
    }
  }
}