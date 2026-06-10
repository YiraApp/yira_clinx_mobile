part of 'prescription_bloc.dart';


enum PrescriptionStatus { initial, loading, success, failure }

@immutable
class PrescriptionState  {
  final PrescriptionStatus status;
  final List<String> diagnoses;
  final List<MedicationItem> medications;
  final bool isPrescriptionExpanded;
  final String? errorMessage;

  const PrescriptionState({
    this.status = PrescriptionStatus.initial,
    this.diagnoses = const [],
    this.medications = const [],
    this.isPrescriptionExpanded = true,
    this.errorMessage,
  });

  PrescriptionState copyWith({
    PrescriptionStatus? status,
    List<String>? diagnoses,
    List<MedicationItem>? medications,
    bool? isPrescriptionExpanded,
    String? errorMessage,
  }) {
    return PrescriptionState(
      status: status ?? this.status,
      diagnoses: diagnoses ?? List<String>.from(this.diagnoses),
      medications: medications ?? List<MedicationItem>.from(this.medications),
      isPrescriptionExpanded: isPrescriptionExpanded ?? this.isPrescriptionExpanded,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }


}
class AddPrescriptionRecordNavState extends PrescriptionState {

}
class SinglePrescriptionDetailsNavState extends PrescriptionState {
  final String prescriptionId;

  const SinglePrescriptionDetailsNavState(this.prescriptionId);

}