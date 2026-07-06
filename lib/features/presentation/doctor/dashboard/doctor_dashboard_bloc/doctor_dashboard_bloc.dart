import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/doctor_dashboard_entity.dart';
import 'package:yiraclinics/features/use_cases/doctor_dashboard_use_case.dart';
import '../../../../../core/local/global_session.dart';
import '../../../../domain/entities/appointments/appointment_entity.dart';

part 'doctor_dashboard_event.dart';
part 'doctor_dashboard_state.dart';

class DoctorDashboardBloc
    extends Bloc<DoctorDashboardEvent, DoctorDashboardState> {
  final DoctorDashboardUseCase doctorDashboardUseCase;
  DoctorDashboardBloc({required this.doctorDashboardUseCase})
    : super(const DoctorDashboardInitial()) {
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
          emit(DoctorDashboardSuccessState(dashboardEntity: dashBoardData));
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
      final cachedState = state;
      emit(DoctorAppointmentsNav());
      if (cachedState is DoctorDashboardLoaded) emit(cachedState);
    });
    on<ViewPatientsEvent>((event, emit) {
      final cachedState = state;
      emit(PatientManagementNav());
      if (cachedState is DoctorDashboardLoaded) emit(cachedState);
    });
    on<DocAndAppPatientDetailsNavEvent>((event, emit) {
      final cachedState = state;
      emit(DocAndAppPatientDetailsNavState());
      if (cachedState is DoctorDashboardLoaded) emit(cachedState);
    });
    on<FetchPatientDetails>((event, emit) async {
      emit(const DoctorDashboardLoading());
      await Future.delayed(const Duration(milliseconds: 400));
      final mockProfileDetails = {
        "name": "mani n",
        "age": 25,
        "gender": "Male",
        "last_updated": "4/6/2026",
        "phone": "9908875796",
        "email": "jmani83280@gmail.com",
        "location": null,
        "vitals": {
          "bp": null,
          "pulse": null,
          "temp": null,
          "spo2": null,
          "weight": null,
          "height": null,
        },
        "insurance": {
          "provider": "sbi",
          "policy_number": "12345",
          "valid_till": null,
        },
        "notes": [
          {
            "doctor": "Dr. Raja Nagalingam",
            "date": "Jun 05",
            "text": "Daily go for a walk",
          },
          {
            "doctor": "Dr. Raja Nagalingam",
            "date": "Jun 05",
            "text": "Do gym on alternative days",
          },
        ],
      };
      emit(PatientDetailsLoadedState(patientData: mockProfileDetails));
    });
  }
}
