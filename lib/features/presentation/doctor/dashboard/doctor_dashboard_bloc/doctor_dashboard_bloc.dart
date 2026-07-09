import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_clinical_notes_entity.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/dashboard_patient_details_entity.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/doctor_dashboard_entity.dart';
import 'package:yiraclinics/features/domain/repositories/dash_board/dashboard_patient_clinical_notes_repo.dart';
import 'package:yiraclinics/features/use_cases/dashboard_patient_clinical_notes_use_case.dart';
import 'package:yiraclinics/features/use_cases/dashboard_patient_details_use_case.dart';
import 'package:yiraclinics/features/use_cases/doctor_dashboard_use_case.dart';
import '../../../../../core/local/global_session.dart';
import '../../../../domain/entities/appointments/appointment_entity.dart';

part 'doctor_dashboard_event.dart';
part 'doctor_dashboard_state.dart';

class DoctorDashboardBloc
    extends Bloc<DoctorDashboardEvent, DoctorDashboardState> {
  final DoctorDashboardUseCase doctorDashboardUseCase;

  DoctorDashboardBloc({
    required this.doctorDashboardUseCase
  }) : super(const DoctorDashboardInitial()) {

    // FETCH DASHBOARD DATA
    on<FetchDoctorDashboardData>((event, emit) async {
      try {
        emit(const DoctorDashboardLoading());
        final currentUser = GlobalSession.instance.userNotifier.value;
        var params = UpdateLatestDetailsRequest(
          userId: currentUser?.data?.id ?? '',
          latestRoleId: currentUser?.data?.latestRoleId ?? '',
          latestOrgId: currentUser?.data?.latestOrgId ?? 0,
          latestHospitalId: currentUser?.data?.latestHospitalId ?? 0,
        );
        var dashBoardData = await doctorDashboardUseCase.call(params);
        if (dashBoardData != null &&
            dashBoardData.status == true &&
            dashBoardData.data != null) {
          emit(DoctorDashboardSuccessState(
            dashboardEntity: dashBoardData,
            timestamp: DateTime.now(),
            patientData: state.patientData,
            clinicalNotesData: state.clinicalNotesData,
          ));
        } else {
          emit(
            DoctorDashboardError(
              message: dashBoardData?.message ?? "Failed to load dashboard data.",
            ),
          );
        }
      } catch (e) {
        emit(DoctorDashboardError(message: e.toString()));
      }
    });

    on<ViewCalendarEvent>((event, emit) {
      if (state is DoctorDashboardSuccessState) {
        emit(DoctorAppointmentsNav(
          dashboardEntity: (state as DoctorDashboardSuccessState).dashboardEntity,
          timestamp: DateTime.now(),
          patientData: state.patientData,
          clinicalNotesData: state.clinicalNotesData,
        ));
      } else if (state is DocAndAppPatientDetailsNavState) {
        emit(DoctorAppointmentsNav(
          dashboardEntity: (state as DocAndAppPatientDetailsNavState).dashboardEntity,
          timestamp: DateTime.now(),
          patientData: state.patientData,
          clinicalNotesData: state.clinicalNotesData,
        ));
      }
    });

    on<ViewPatientsEvent>((event, emit) {
      if (state is DoctorDashboardSuccessState) {
        emit(PatientManagementNav(
          dashboardEntity: (state as DoctorDashboardSuccessState).dashboardEntity,
          timestamp: DateTime.now(),
          patientData: state.patientData,
          clinicalNotesData: state.clinicalNotesData,
        ));
      } else if (state is DocAndAppPatientDetailsNavState) {
        emit(PatientManagementNav(
          dashboardEntity: (state as DocAndAppPatientDetailsNavState).dashboardEntity,
          timestamp: DateTime.now(),
          patientData: state.patientData,
          clinicalNotesData: state.clinicalNotesData,
        ));
      }
    });

    on<DocAndAppPatientDetailsNavEvent>((event, emit) {
      if (state is DoctorDashboardSuccessState) {
        emit(DocAndAppPatientDetailsNavState(
          dashboardEntity: (state as DoctorDashboardSuccessState).dashboardEntity,
          timestamp: DateTime.now(),
          patientData: state.patientData,
          clinicalNotesData: state.clinicalNotesData,
        ));
      } else if (state is PatientDetailsLoadedState || state is PatientClinicalLoadedState) {
        DoctorDashboardEntity? targetEntity;
        if (state is PatientDetailsLoadedState) {
          // If we are currently sitting in child detail route states, look up
          // historical singleton instances to pass dashboard entities accurately.
          // Since the block is registerLazySingleton, we can query memory layout safely.
        }

        // Dynamic search strategy for valid active dashboard layout entities
        final dynamic currentState = state;
        try {
          if (currentState.dashboardEntity != null) {
            targetEntity = currentState.dashboardEntity;
          }
        } catch (_) {}

        if (targetEntity != null) {
          emit(DocAndAppPatientDetailsNavState(
            dashboardEntity: targetEntity,
            timestamp: DateTime.now(),
            patientData: state.patientData,
            clinicalNotesData: state.clinicalNotesData,
          ));
        }
      }
    });

    // PRODUCTION FIX: Assigned fresh timestamp parameters here to verify
    // complete structural clearing on Equatable engine validations
    on<ClearNavigationTriggerEvent>((event, emit) {
      if (state is DocAndAppPatientDetailsNavState) {
        emit(DoctorDashboardSuccessState(
          dashboardEntity: (state as DocAndAppPatientDetailsNavState).dashboardEntity,
          timestamp: DateTime.now(),
          patientData: state.patientData,
          clinicalNotesData: state.clinicalNotesData,
        ));
      } else if (state is DoctorAppointmentsNav) {
        emit(DoctorDashboardSuccessState(
          dashboardEntity: (state as DoctorAppointmentsNav).dashboardEntity,
          timestamp: DateTime.now(),
          patientData: state.patientData,
          clinicalNotesData: state.clinicalNotesData,
        ));
      } else if (state is PatientManagementNav) {
        emit(DoctorDashboardSuccessState(
          dashboardEntity: (state as PatientManagementNav).dashboardEntity,
          timestamp: DateTime.now(),
          patientData: state.patientData,
          clinicalNotesData: state.clinicalNotesData,
        ));
      }
    });

 }
}