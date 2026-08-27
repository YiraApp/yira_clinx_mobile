part of 'dashboard_bloc.dart';



enum DashboardStatus { initial, loading, success, failure }
@immutable

class DashboardState extends Equatable {
  final DashboardStatus status;
  final List<PatientEntity> patients;
  final List<PatientEntity> allFilteredPatients;
  final List<PatientEntity> allPatients;
  final String? selectedStatus;
  final String? selectedGender;
  final String searchQuery;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.patients = const [],
    this.allFilteredPatients = const [],
    this.allPatients = const [],
    this.selectedStatus,
    this.selectedGender,
    this.searchQuery = '',
    this.currentPage = 1,
    this.pageSize = 15,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    List<PatientEntity>? patients,
    List<PatientEntity>? allFilteredPatients,
    List<PatientEntity>? allPatients,
    String? Function()? selectedStatus,
    String? Function()? selectedGender,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      patients: patients ?? this.patients,
      allFilteredPatients: allFilteredPatients ?? this.allFilteredPatients,
      allPatients: allPatients ?? this.allPatients,
      selectedStatus: selectedStatus != null ? selectedStatus() : this.selectedStatus,
      selectedGender: selectedGender != null ? selectedGender() : this.selectedGender,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        patients,
        allFilteredPatients,
        allPatients,
        selectedStatus,
        selectedGender,
        searchQuery,
        currentPage,
        pageSize,
        hasMore,
        isLoadingMore,
        errorMessage,
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
  }) : timestamp = time ?? DateTime.now();

  @override
  List<Object?> get props => [patientId, patientName, timestamp];
}
