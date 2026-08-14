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
import '../dashboard_patient_details_screen.dart';

part 'doctor_dashboard_event.dart';
part 'doctor_dashboard_state.dart';

class DoctorDashboardBloc
    extends Bloc<DoctorDashboardEvent, DoctorDashboardState> {
  final DoctorDashboardUseCase doctorDashboardUseCase;

  DoctorDashboardEntity? _cachedDashboardEntity;

  DoctorDashboardBloc({required this.doctorDashboardUseCase})
    : super(const DoctorDashboardInitial()) {
    on<FetchDoctorDashboardData>((event, emit) async {
      try {
        if (!event.isRefresh) {
          emit(const DoctorDashboardLoading());
        }
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
          _cachedDashboardEntity = dashBoardData;

          emit(
            DoctorDashboardSuccessState(
              dashboardEntity: dashBoardData,
              timestamp: DateTime.now(),
              patientData: state.patientData,
              clinicalNotesData: state.clinicalNotesData,
            ),
          );
        } else {
          emit(
            DoctorDashboardError(
              message:
                  dashBoardData?.message ?? "Failed to load dashboard data.",
            ),
          );
        }
      } catch (e) {
        emit(DoctorDashboardError(message: e.toString()));
      }
    });

    on<ViewCalendarEvent>((event, emit) {
      if (state is DoctorDashboardSuccessState) {
        emit(
          DoctorAppointmentsNav(
            dashboardEntity:
                (state as DoctorDashboardSuccessState).dashboardEntity,
            timestamp: DateTime.now(),
            patientData: state.patientData,
            clinicalNotesData: state.clinicalNotesData,
          ),
        );
      }
    });

    on<ViewPatientsEvent>((event, emit) {
      if (state is DoctorDashboardSuccessState) {
        emit(
          PatientManagementNav(
            dashboardEntity:
                (state as DoctorDashboardSuccessState).dashboardEntity,
            timestamp: DateTime.now(),
            patientData: state.patientData,
            clinicalNotesData: state.clinicalNotesData,
          ),
        );
      }
    });

    on<DocAndAppPatientDetailsNavEvent>((event, emit) {
      emit(
        DocAndAppPatientDetailsNavState(
          patientDetails: event.details,
          timestamp: DateTime.now(),
          patientData: state.patientData,
          clinicalNotesData: state.clinicalNotesData,
        ),
      );
    });

    on<ClearNavigationTriggerEvent>((event, emit) {
      if (state is DoctorAppointmentsNav) {
        emit(
          DoctorDashboardSuccessState(
            dashboardEntity: (state as DoctorAppointmentsNav).dashboardEntity,
            timestamp: DateTime.now(),
            patientData: state.patientData,
            clinicalNotesData: state.clinicalNotesData,
          ),
        );
      } else if (state is PatientManagementNav) {
        emit(
          DoctorDashboardSuccessState(
            dashboardEntity: (state as PatientManagementNav).dashboardEntity,
            timestamp: DateTime.now(),
            patientData: state.patientData,
            clinicalNotesData: state.clinicalNotesData,
          ),
        );
      } else if (state is DocAndAppPatientDetailsNavState) {
        if (_cachedDashboardEntity != null) {
          emit(
            DoctorDashboardSuccessState(
              dashboardEntity: _cachedDashboardEntity!,
              timestamp: DateTime.now(),
              patientData: state.patientData,
              clinicalNotesData: state.clinicalNotesData,
            ),
          );
        } else {
          add(FetchDoctorDashboardData());
        }
      }
    });
  }
}
