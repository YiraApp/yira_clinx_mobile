import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../../core/local/global_session.dart';
import '../../../domain/entities/appointments/appointment_entity.dart';
import '../../../domain/repositories/appointments/appointment_repo.dart';
import '../../../use_cases/get_appointment_dashboard_use_case.dart';

part 'appointment_event.dart';
part 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final GetAppointmentDashboardUseCase getAppointmentDashboardUseCase;
  final AppointmentRepo appointmentRepo;

  AppointmentBloc({
    required this.getAppointmentDashboardUseCase,
    required this.appointmentRepo,
  }) : super(AppointmentInitial()) {
    on<LoadAppointmentsEvent>((event, emit) async {
      emit(AppointmentLoading());
      try {
        final currentUser = GlobalSession.instance.userNotifier.value;
        final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
            ? currentUser.data!.id!.trim()
            : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
                ? currentUser.data!.navigationId!.trim()
                : '1';
        final int orgId = currentUser?.data?.latestOrgId ?? 1;
        final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;

        final result = await getAppointmentDashboardUseCase(
          doctorId: doctorId,
          orgId: orgId,
          hospitalId: hospitalId,
          status: event.status,
          search: event.search,
          date: event.date,
          dateFrom: event.dateFrom,
          dateTo: event.dateTo,
        );

        if (result != null) {
          emit(AppointmentLoaded(
            appointments: result.appointments,
            todayCount: result.todayCount,
            confirmedCount: result.confirmedCount,
            pendingCount: result.pendingCount,
            aiOptimizationScore: result.aiOptimizationScore,
          ));
        } else {
          emit(AppointmentLoaded(
            appointments: const [],
            todayCount: 0,
            confirmedCount: 0,
            pendingCount: 0,
            aiOptimizationScore: 94,
          ));
        }
      } catch (e) {
        emit(AppointmentError("Failed to fetch appointment dashboard records: $e"));
      }
    });

    on<OnAddAppointmentEvent>((event, emit) async {
      emit(OnAddAppointmentState());
    });

    on<SubmitBookAppointmentEvent>((event, emit) async {
      emit(const BookAppointmentLoadingState());
      try {
        final currentUser = GlobalSession.instance.userNotifier.value;
        final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
            ? currentUser.data!.id!.trim()
            : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
                ? currentUser.data!.navigationId!.trim()
                : '1';
        final int orgId = currentUser?.data?.latestOrgId ?? 1;
        final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;

        final success = await appointmentRepo.bookAppointment(
          doctorId: doctorId,
          orgId: orgId,
          hospitalId: hospitalId,
          patientName: event.patientName,
          patientPhone: event.phoneNumber,
          gender: event.gender,
          dob: event.dob,
          appointmentDate: event.appointmentDate,
          startTime: event.startTime,
          reason: event.reason,
          appointmentType: event.appointmentType,
          isTeleConsultation: event.isTeleConsultation,
          parentAppointmentId: event.parentAppointmentId,
          treatmentPlanIds: event.treatmentPlanIds,
          customTreatmentPlans: event.customTreatmentPlans,
          discountAmount: event.discountAmount,
        );

        if (success) {
          emit(BookAppointmentSuccessState(
            message: "Appointment booked successfully!",
            patientName: event.patientName,
            appointmentDate: event.appointmentDate,
            time: event.startTime,
            isTeleConsultation: event.isTeleConsultation ?? false,
          ));
          add(LoadAppointmentsEvent());
        } else {
          emit(const AppointmentError("Failed to book appointment. Please try again."));
        }
      } catch (e) {
        emit(AppointmentError("Failed to book appointment: $e"));
      }
    });

    on<UpdateAppointmentStatusEvent>((event, emit) async {
      try {
        final success = await appointmentRepo.updateAppointmentStatus(
          appointmentId: event.appointmentId,
          status: event.status,
        );

        if (success) {
          add(LoadAppointmentsEvent());
        } else {
          emit(AppointmentError("Failed to update appointment status"));
        }
      } catch (e) {
        emit(AppointmentError("Failed to update appointment status: $e"));
      }
    });
  }
}
