part of 'prescription_bloc.dart';


@immutable

abstract class MedicationEvent extends Equatable {
  const MedicationEvent();
  @override
  List<Object?> get props => [];
}

class LoadMedicationData extends MedicationEvent {}

class FilterByStatus extends MedicationEvent {
  final String status;
  const FilterByStatus(this.status);
  @override
  List<Object?> get props => [status];
}

class LoadPrescriptionDetails extends MedicationEvent {
  final String prescriptionId;
  const LoadPrescriptionDetails(this.prescriptionId);
  @override
  List<Object?> get props => [prescriptionId];
}