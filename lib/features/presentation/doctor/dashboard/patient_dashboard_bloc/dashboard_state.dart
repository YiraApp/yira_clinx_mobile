part of 'dashboard_bloc.dart';



enum DashboardStatus { initial, loading, success, failure }
@immutable

class DashboardState extends Equatable {
  final DashboardStatus status;
  final List<PatientEntity> patients;
  final List<PatientEntity> allPatients;
  final List<PatientEntity> filteredPatients;
  final String? selectedStatus;
  final String? selectedGender;
  final String? errorMessage;
  final int visibleCount;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchQuery;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.patients = const [],
    this.allPatients = const [],
    this.filteredPatients = const [],
    this.selectedStatus,
    this.selectedGender,
    this.errorMessage,
    this.visibleCount = 20,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.searchQuery = "",
  });

  DashboardState copyWith({
    DashboardStatus? status,
    List<PatientEntity>? patients,
    List<PatientEntity>? allPatients,
    List<PatientEntity>? filteredPatients,
    String? Function()? selectedStatus,
    String? Function()? selectedGender,
    String? errorMessage,
    int? visibleCount,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
  }) {
    return DashboardState(
      status: status ?? this.status,
      patients: patients ?? this.patients,
      allPatients: allPatients ?? this.allPatients,
      filteredPatients: filteredPatients ?? this.filteredPatients,
      // If the function is provided, we call it (even if it returns null)
      selectedStatus: selectedStatus != null ? selectedStatus() : this.selectedStatus,
      selectedGender: selectedGender != null ? selectedGender() : this.selectedGender,
      errorMessage: errorMessage ?? this.errorMessage,
      visibleCount: visibleCount ?? this.visibleCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        status,
        patients,
        allPatients,
        filteredPatients,
        selectedStatus,
        selectedGender,
        errorMessage,
        visibleCount,
        hasMore,
        isLoadingMore,
        searchQuery,
      ];
}
class ViewPatientDetailsState extends DashboardState {
  final String? patientId;
  final String? patientName;
  final DateTime timestamp;

  ViewPatientDetailsState({
    this.patientId,
    this.patientName,
    DateTime? time,
    super.status,
    super.patients,
    super.allPatients,
    super.filteredPatients,
    super.selectedStatus,
    super.selectedGender,
    super.errorMessage,
    super.visibleCount,
    super.hasMore,
    super.isLoadingMore,
    super.searchQuery,
  }) : timestamp = time ?? DateTime.now();

  @override
  List<Object?> get props => [
        patientId,
        patientName,
        timestamp,
        status,
        patients,
        allPatients,
        filteredPatients,
        selectedStatus,
        selectedGender,
        errorMessage,
        visibleCount,
        hasMore,
        isLoadingMore,
        searchQuery,
      ];
}
