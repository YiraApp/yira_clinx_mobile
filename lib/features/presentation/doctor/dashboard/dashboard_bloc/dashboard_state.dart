part of 'dashboard_bloc.dart';



enum DashboardStatus { initial, loading, success, failure }
@immutable
// presentation/bloc/dashboard/dashboard_state.dart

class DashboardState extends Equatable {
  final DashboardStatus status;
  final List<PatientEntity> patients;
  final List<PatientEntity> allPatients;
  final String? selectedStatus;
  final String? selectedGender;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.patients = const [],
    this.allPatients = const [],
    this.selectedStatus,
    this.selectedGender,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    List<PatientEntity>? patients,
    List<PatientEntity>? allPatients,
    // We wrap these in a function or use a flag to allow null
    String? Function()? selectedStatus,
    String? Function()? selectedGender,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      patients: patients ?? this.patients,
      allPatients: allPatients ?? this.allPatients,
      // If the function is provided, we call it (even if it returns null)
      selectedStatus: selectedStatus != null ? selectedStatus() : this.selectedStatus,
      selectedGender: selectedGender != null ? selectedGender() : this.selectedGender,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, patients, allPatients, selectedStatus, selectedGender, errorMessage];
}
