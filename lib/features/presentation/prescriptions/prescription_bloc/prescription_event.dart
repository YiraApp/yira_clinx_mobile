part of 'prescription_bloc.dart';

@immutable
abstract class PrescriptionEvent {
  const PrescriptionEvent();
}

class LoadPrescriptionData extends PrescriptionEvent {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  const LoadPrescriptionData({
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
  });
}

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

class AddEmptyMedication extends PrescriptionEvent {}

class RemoveMedication extends PrescriptionEvent {
  final String id;
  const RemoveMedication(this.id);
}

class UpdateMedicationDetails extends PrescriptionEvent {
  final String id;
  final String? name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? route;
  final String? instructions;

  const UpdateMedicationDetails({
    required this.id,
    this.name,
    this.dosage,
    this.frequency,
    this.duration,
    this.route,
    this.instructions,
  });
}

class TogglePrescriptionExpansion extends PrescriptionEvent {}

/// Loads the hospital's lab tests once; after a failure it tries again.
class LoadLabTestCatalog extends PrescriptionEvent {
  final String? hospitalId;
  const LoadLabTestCatalog(this.hospitalId);
}

class SetLabTests extends PrescriptionEvent {
  final List<PrescribedLabTest> tests;
  const SetLabTests(this.tests);
}

class RemoveLabTest extends PrescriptionEvent {
  final String key;
  const RemoveLabTest(this.key);
}

class UpdateLabTest extends PrescriptionEvent {
  final String key;
  final String? priority;
  final String? instructions;

  const UpdateLabTest({required this.key, this.priority, this.instructions});
}

class SubmitPrescription extends PrescriptionEvent {
  final String patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final String additionalNotes;
  final String? medicalRecordId;

  const SubmitPrescription({
    required this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    required this.additionalNotes,
    this.medicalRecordId,
  });
}

class AddPrescriptionRecordNavEvent extends PrescriptionEvent {}

class SinglePrescriptionDetailsNavEvent extends PrescriptionEvent {
  final String prescriptionId;
  const SinglePrescriptionDetailsNavEvent({required this.prescriptionId});
}

class ResetPrescriptionNavigationEvent extends PrescriptionEvent {}