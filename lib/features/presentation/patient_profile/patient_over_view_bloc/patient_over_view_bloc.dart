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
    on<LoadPatientData>((event, emit) async {
      emit(LoadingPatientViewDetails());
      try {
        final data = await patientOverViewUseCase.call(
          event.patientId,
          orgId: event.orgId,
          hospitalId: event.hospitalId,
        );

        if (data == null || !(data.status ?? false)) {
          final failureMessage =
              data?.message ?? "Failed to fetch patient overview details.";
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
            "Failed to fetch patient overview details.",
          ),
        );
      }
    });
  }
}
