part of 'prescription_bloc.dart';

enum MedicationStatus { initial, loading, success, failure }


@immutable

class MedicationState extends Equatable {
  final MedicationStatus status;
  final MedicationEntity? summary;
  final List<Map<String, dynamic>> allPrescriptions;
  final List<Map<String, dynamic>> filteredPrescriptions;
  final Map<String, dynamic>? selectedPrescriptionDetail;
  final String? selectedStatus;
  final String? error;

  const MedicationState({
    this.status = MedicationStatus.initial,
    this.summary,
    this.allPrescriptions = const [],
    this.filteredPrescriptions = const [],
    this.selectedPrescriptionDetail,
    this.selectedStatus = "All",
    this.error,
  });

  MedicationState copyWith({
    MedicationStatus? status,
    MedicationEntity? summary,
    List<Map<String, dynamic>>? allPrescriptions,
    List<Map<String, dynamic>>? filteredPrescriptions,
    Map<String, dynamic>? selectedPrescriptionDetail,
    String? selectedStatus,
    String? error,
  }) {
    return MedicationState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      allPrescriptions: allPrescriptions ?? this.allPrescriptions,
      filteredPrescriptions: filteredPrescriptions ?? this.filteredPrescriptions,
      selectedPrescriptionDetail: selectedPrescriptionDetail ?? this.selectedPrescriptionDetail,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, summary, allPrescriptions, filteredPrescriptions, selectedPrescriptionDetail, selectedStatus, error];
}
