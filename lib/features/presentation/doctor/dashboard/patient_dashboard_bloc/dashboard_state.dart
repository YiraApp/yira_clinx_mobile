part of 'dashboard_bloc.dart';



enum DashboardStatus { initial, loading, success, failure }
@immutable

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
class ViewPatientDetailsState extends DashboardState{

  @override
  List<Object?> get props => [];
}
