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
    String? patientUserId,
    String? parentUserId,
    String? relation,
    bool? isPrimary,
    String? patientName,
    String? patientEmail,
    String? gender,
    String? dob,
    String? appointmentDate,
    String? startTime,
    String? reason,
    String? appointmentType,
    bool? isTeleConsultation,
    int? parentAppointmentId,
    List<String>? treatmentPlanIds,
    List<Map<String, dynamic>>? customTreatmentPlans,
    double? discountAmount,
    bool? includeConsultationFee,
    double? consultationFee,
  });

  Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  });
}
