part of 'prescription_bloc.dart';

@immutable
abstract class PrescriptionEvent extends Equatable {
  const PrescriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadPrescriptionData extends PrescriptionEvent {}

class AddDiagnosis extends PrescriptionEvent {
  final String diagnosis;
  const AddDiagnosis(this.diagnosis);

  @override
  List<Object> get props => [diagnosis];
}

class RemoveDiagnosis extends PrescriptionEvent {
  final String diagnosis;
  const RemoveDiagnosis(this.diagnosis);

  @override
  List<Object> get props => [diagnosis];
}

class AddMedication extends PrescriptionEvent {
  final String medicationName;
  const AddMedication(this.medicationName);

  @override
  List<Object> get props => [medicationName];
}

class RemoveMedication extends PrescriptionEvent {
  final String id;
  const RemoveMedication(this.id);

  @override
  List<Object> get props => [id];
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

  @override
  List<Object?> get props => [id, dosage, frequency, duration, route];
}

class TogglePrescriptionExpansion extends PrescriptionEvent {}
class SubmitPrescription extends PrescriptionEvent {
  final String patientId;
  final String additionalNotes;

  const SubmitPrescription({
    required this.patientId,
    required this.additionalNotes,
  });

  @override
  List<Object> get props => [patientId, additionalNotes];
}