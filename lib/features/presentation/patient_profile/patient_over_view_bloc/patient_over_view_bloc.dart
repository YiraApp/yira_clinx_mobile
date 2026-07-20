import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/features/domain/entities/over_view/over_view_entity.dart';
import 'package:yiraclinics/features/use_cases/patient_over_view_use_case.dart';
part 'patient_over_view_event.dart';
part 'patient_over_view_state.dart';

class PatientOverViewBloc
    extends Bloc<PatientOverViewEvent, PatientOverViewState> {
  final PatientOverViewUseCase patientOverViewUseCase;
  PatientOverViewBloc({required this.patientOverViewUseCase})
    : super(PatientOverViewInitial()) {
    on<PatientOverViewEvent>((event, emit) {});
    on<LoadPatientData>((event, emit) async {
      emit(LoadingPatientViewDetails());
      try {
        final data = await patientOverViewUseCase.call(event.patientId);

        if (data == null || !(data.status ?? false)) {
          final failureMessage =
              data?.message ?? "Failed to fetch patient over view details.";
          emit(LoadPatientDataFailureState(failureMessage));
          return;
        }
        emit(LoadPatientDataState(data));
      } catch (versionError, stackTrace) {
        debugPrint(
          "CRITICAL: Telemetry evaluation failed: $versionError\n$stackTrace",
        );
        emit(
          LoadPatientDataFailureState(
            "CRITICAL: Telemetry evaluation failed: $versionError\n$stackTrace",
          ),
        );
      }
    });
  }
}
