import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../domain/entities/dashboard/dashboard_patient_clinical_notes_entity.dart';
import '../../../../domain/entities/dashboard/dashboard_patient_details_entity.dart';
import '../../../../use_cases/dashboard_patient_clinical_notes_use_case.dart';
import '../../../../use_cases/dashboard_patient_details_use_case.dart';

part 'patient_details_event.dart';
part 'patient_details_state.dart';

class PatientDetailsBloc extends Bloc<PatientDetailsEvent, PatientDetailsState> {
  final DashboardPatientDetailsUseCase detailsUseCase;
  final DashboardPatientClinicalNotesUseCase clinicalUseCase;

  PatientDetailsBloc({
    required this.detailsUseCase,
    required this.clinicalUseCase,
  }) : super(PatientDetailsInitial()) {
    on<LoadPatientScreenData>((event, emit) async {
      emit(PatientDetailsLoading(patientData: state.patientData, clinicalNotesData: state.clinicalNotesData));

      try {
        final params = PatientDetailsParams(
          appointmentId: event.appointmentId,
          patientId: event.patientId,
          orgId: event.orgId,
          hospitalId: event.hospitalId,
        );
        final results = await Future.wait([
          detailsUseCase.call(params),
          clinicalUseCase.call(params),
        ]);

        final detailsRes = results[0] as DashBoardPatientDetailsEntity?;
        final clinicalRes = results[1] as DashBoardPatientDetailsClinicalNotesEntity?;

        if (detailsRes?.status == true && detailsRes?.data != null) {
          emit(PatientDetailsLoaded(
            patientData: detailsRes,
            clinicalNotesData: clinicalRes,
          ));
        } else {
          emit(PatientDetailsError(
            message: detailsRes?.message ?? "Failed to capture patient profile data.",
            patientData: state.patientData,
            clinicalNotesData: state.clinicalNotesData,
          ));
        }
      } catch (e) {
        emit(PatientDetailsError(message: e.toString(), patientData: state.patientData, clinicalNotesData: state.clinicalNotesData));
      }
    });
  }
}
