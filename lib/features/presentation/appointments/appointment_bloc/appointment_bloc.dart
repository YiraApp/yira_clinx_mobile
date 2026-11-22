import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
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

  String? _currentDate;
  String? _currentDateFrom;
  String? _currentDateTo;
  String? _currentStatus;
  String? _currentSearch;

  AppointmentBloc({
    required this.getAppointmentDashboardUseCase,
    required this.appointmentRepo,
  }) : super(AppointmentInitial()) {
    on<LoadAppointmentsEvent>((event, emit) async {
      emit(AppointmentLoading());
      try {
        if (event.date != null || event.dateFrom != null || event.dateTo != null || event.status != null || event.search != null) {
          _currentDate = event.date;
          _currentDateFrom = event.dateFrom;
          _currentDateTo = event.dateTo;
          _currentStatus = event.status;
          _currentSearch = event.search;
        }

        final todayIso = DateTime.now().toIso8601String().split('T')[0];
        final targetDate = (event.dateFrom == null && event.dateTo == null && _currentDateFrom == null && _currentDateTo == null)
            ? (event.date ?? _currentDate ?? todayIso)
            : (event.date ?? _currentDate);
        final targetDateFrom = event.dateFrom ?? _currentDateFrom;
        final targetDateTo = event.dateTo ?? _currentDateTo;
        final targetStatus = event.status ?? _currentStatus;
        final targetSearch = event.search ?? _currentSearch;

        final currentUser = GlobalSession.instance.userNotifier.value;
        final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
            ? currentUser.data!.id!.trim()
            : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
                ? currentUser.data!.navigationId!.trim()
                : '1';
        final int orgId = currentUser?.data?.latestOrgId ?? 1;
        final int hospitalId = (currentUser?.data?.latestHospitalId != null && currentUser!.data!.latestHospitalId! > 0)
            ? currentUser.data!.latestHospitalId!
            : 0;

        final result = await getAppointmentDashboardUseCase(
          doctorId: doctorId,
          orgId: orgId,
          hospitalId: hospitalId,
          status: targetStatus,
          search: targetSearch,
          date: targetDate,
          dateFrom: targetDateFrom,
          dateTo: targetDateTo,
        );

        if (result != null) {
          emit(AppointmentLoaded(
            appointments: result.appointments,
            todayCount: result.todayCount,
            confirmedCount: result.confirmedCount,
            pendingCount: result.pendingCount,
            completedCount: result.completedCount,
            aiOptimizationScore: result.aiOptimizationScore,
          ));
        } else {
          emit(AppointmentLoaded(
            appointments: const [],
            todayCount: 0,
            confirmedCount: 0,
            pendingCount: 0,
            completedCount: 0,
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
        final String doctorId = (event.doctorId != null && event.doctorId!.trim().isNotEmpty)
            ? event.doctorId!.trim()
            : ((currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
                ? currentUser.data!.id!.trim()
                : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
                    ? currentUser.data!.navigationId!.trim()
                    : '1');
        final int orgId = event.orgId ?? (currentUser?.data?.latestOrgId ?? 1);
        final int hospitalId = event.hospitalId ?? (currentUser?.data?.latestHospitalId ?? 1);

        final bookingData = await appointmentRepo.bookAppointment(
          doctorId: doctorId,
          orgId: orgId,
          hospitalId: hospitalId,
          patientUserId: event.patientUserId,
          parentUserId: event.parentUserId,
          relation: event.relation,
          isPrimary: event.isPrimary,
          patientName: event.patientName,
          patientPhone: event.phoneNumber,
          countryCode: event.countryCode,
          patientEmail: event.patientEmail,
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
          includeConsultationFee: event.includeConsultationFee,
          consultationFee: event.consultationFee,
          shareRecords: event.grantRecordAccess,
          shareRecordsDuration: event.shareRecordsDuration,
        );

        if (bookingData != null) {
          int? appointmentId;
          String? patientUserId;
          final d = bookingData['data'];
          if (d is Map<String, dynamic>) {
            appointmentId = int.tryParse(d['appointmentId']?.toString() ?? '');
            patientUserId = d['patientUserId']?.toString();
          }
          appointmentId ??= int.tryParse(bookingData['appointmentId']?.toString() ?? '');

          // A server from before the duration choice always gives 7 days and doesn't
          // report recordAccess; then give the chosen duration with the share call.
          if (event.grantRecordAccess &&
              event.shareRecordsDuration != '7_DAYS' &&
              (d is! Map<String, dynamic> || d['recordAccess'] == null) &&
              (patientUserId ?? '').isNotEmpty &&
              doctorId.isNotEmpty) {
            await _shareRecordsFor(patientUserId!, doctorId, event.shareRecordsDuration, hospitalId);
          }

          emit(BookAppointmentSuccessState(
            message: "Appointment booked successfully!",
            patientName: event.patientName,
            appointmentDate: event.appointmentDate,
            time: event.startTime,
            isTeleConsultation: event.isTeleConsultation ?? false,
            appointmentId: appointmentId,
            patientUserId: patientUserId ?? event.patientUserId,
            consultationFee: event.consultationFee,
            doctorId: doctorId,
            hospitalId: hospitalId,
            patientPhone: event.phoneNumber,
            patientEmail: event.patientEmail,
          ));
          add(LoadAppointmentsEvent(
            date: _currentDate,
            dateFrom: _currentDateFrom,
            dateTo: _currentDateTo,
            status: _currentStatus,
            search: _currentSearch,
          ));
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
          add(LoadAppointmentsEvent(
            date: _currentDate,
            dateFrom: _currentDateFrom,
            dateTo: _currentDateTo,
            status: _currentStatus,
            search: _currentSearch,
          ));
        } else {
          emit(AppointmentError("Failed to update appointment status"));
        }
      } catch (e) {
        emit(AppointmentError("Failed to update appointment status: $e"));
      }
    });
  }

  /// Gives [doctorId] access to [patientId]'s records for [duration]. Booking has
  /// already succeeded, so a failure here is only logged.
  Future<void> _shareRecordsFor(String patientId, String doctorId, String duration, int hospitalId) async {
    try {
      await sl<ApiClient>().account(showSuccessSnack: false).post(
            URLs.patientAccessGrantUrl,
            data: {'patientId': patientId, 'doctorId': doctorId, 'duration': duration, 'hospitalId': hospitalId},
            options: Options(extra: const {'showSuccessSnack': false, 'suppressErrorSnack': true}),
          );
    } catch (e) {
      debugPrint('[AppointmentBloc] Could not share records for $duration: $e');
    }
  }
}
