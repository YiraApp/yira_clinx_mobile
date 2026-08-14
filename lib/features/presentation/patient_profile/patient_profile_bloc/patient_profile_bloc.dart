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
    on<TabChanged>(_onTabChanged);
  }

  // Extracted to its own method to keep the constructor clean and readable
  void _onTabChanged(TabChanged event, Emitter<PatientProfileState> emit) {
    if (state is PatientProfileLoaded) {
      final currentState = state as PatientProfileLoaded;
      emit(currentState.copyWith(activeTabIndex: event.activeTabIndex));
    }
  }

  Future<void> _onLoadPatientProfile(
      LoadPatientProfile event,
      Emitter<PatientProfileState> emit,
      ) async {
    emit(PatientProfileLoading());
    try {
      final patient = await repository.getPatientProfile(
        event.patientId,
        patientName: event.patientName,
      );

      // Explicitly pass activeTabIndex: 0 to ensure Overview is the starting tab
      emit(PatientProfileLoaded(patient: patient, activeTabIndex: 0));
    } catch (e) {
      emit(PatientProfileError(e.toString()));
    }
  }
}