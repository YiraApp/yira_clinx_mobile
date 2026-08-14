import '../data/models/appointments/appointment_model.dart';
import '../domain/repositories/appointments/appointment_repo.dart';

class GetAppointmentDashboardUseCase {
  final AppointmentRepo repository;

  GetAppointmentDashboardUseCase(this.repository);

  Future<AppointmentDashboardDataModel?> call({
    required String doctorId,
    required int orgId,
    required int hospitalId,
    String? status,
    String? search,
    String? date,
    String? dateFrom,
    String? dateTo,
  }) {
    return repository.fetchAppointmentDashboard(
      doctorId: doctorId,
      orgId: orgId,
      hospitalId: hospitalId,
      status: status,
      search: search,
      date: date,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
