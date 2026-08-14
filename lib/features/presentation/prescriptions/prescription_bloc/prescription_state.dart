part of 'prescription_bloc.dart';


enum PrescriptionStatus { initial, loading, success, failure, submitLoading, submitSuccess, submitFailure }

@immutable
class PrescriptionState  {
  final PrescriptionStatus status;
  final List<String> diagnoses;
  final List<MedicationItem> medications;
  final String additionalNotes;
  final bool isPrescriptionExpanded;
  final String? errorMessage;

  PrescriptionState({
    this.status = PrescriptionStatus.success,
    this.diagnoses = const [],
    List<MedicationItem>? medications,
    this.additionalNotes = '',
    this.isPrescriptionExpanded = true,
    this.errorMessage,
  }) : medications = medications ??
            [
              MedicationItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: '',
              ),
            ];

  PrescriptionState copyWith({
    PrescriptionStatus? status,
    List<String>? diagnoses,
    List<MedicationItem>? medications,
    String? additionalNotes,
    bool? isPrescriptionExpanded,
    String? errorMessage,
  }) {
    return PrescriptionState(
      status: status ?? this.status,
      diagnoses: diagnoses ?? List<String>.from(this.diagnoses),
      medications: medications ?? List<MedicationItem>.from(this.medications),
      additionalNotes: additionalNotes ?? this.additionalNotes,
      isPrescriptionExpanded: isPrescriptionExpanded ?? this.isPrescriptionExpanded,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }


}
class AddPrescriptionRecordNavState extends PrescriptionState {

}
class SinglePrescriptionDetailsNavState extends PrescriptionState {
  final String prescriptionId;

  SinglePrescriptionDetailsNavState(this.prescriptionId);

}