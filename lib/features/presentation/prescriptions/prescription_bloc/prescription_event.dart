part of 'prescription_bloc.dart';

@immutable
abstract class PrescriptionEvent  {
  const PrescriptionEvent();


}

class LoadPrescriptionData extends PrescriptionEvent {}

class AddDiagnosis extends PrescriptionEvent {
  final String diagnosis;
  const AddDiagnosis(this.diagnosis);


}

class RemoveDiagnosis extends PrescriptionEvent {
  final String diagnosis;
  const RemoveDiagnosis(this.diagnosis);

}

class AddMedication extends PrescriptionEvent {
  final String medicationName;
  const AddMedication(this.medicationName);

}

class RemoveMedication extends PrescriptionEvent {
  final String id;
  const RemoveMedication(this.id);


}

class UpdateMedicationDetails extends PrescriptionEvent {
  final String id;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? route;

  const UpdateMedicationDetails({
    required this.id,
    this.dosage,
    this.frequency,
    this.duration,
    this.route,
  });


}

class TogglePrescriptionExpansion extends PrescriptionEvent {}

class SubmitPrescription extends PrescriptionEvent {
  final String patientId;
  final String additionalNotes;

  const SubmitPrescription({
    required this.patientId,
    required this.additionalNotes,
  });


}


class AddPrescriptionRecordNavEvent extends PrescriptionEvent {}

class SinglePrescriptionDetailsNavEvent extends PrescriptionEvent {
  final String prescriptionId;
  const SinglePrescriptionDetailsNavEvent({required this.prescriptionId});

}
class ResetPrescriptionNavigationEvent extends PrescriptionEvent {}