import '../../../data/models/appointments/appointment_model.dart';

abstract class AppointmentRepo {
  Future<AppointmentDashboardDataModel?> fetchAppointmentDashboard({
    required String doctorId,
    required int orgId,
    required int hospitalId,
    String? status,
    String? search,
    String? date,
    String? dateFrom,
    String? dateTo,
  });

  Future<bool> bookAppointment({
    required String doctorId,
    required int orgId,
    required int hospitalId,
    required String patientPhone,
    String? patientName,
    String? gender,
    String? dob,
    String? appointmentDate,
    String? startTime,
    String? reason,
    String? appointmentType,
    bool? isTeleConsultation,
  });

  Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  });
}
