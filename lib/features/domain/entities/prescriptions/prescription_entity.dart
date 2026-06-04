import 'package:equatable/equatable.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_item.dart';


class PrescriptionEntity extends Equatable {
  final String patientId;
  final List<String> diagnoses;
  final List<MedicationItem> medications;
  final String additionalNotes;

  const PrescriptionEntity({
    required this.patientId,
    required this.diagnoses,
    required this.medications,
    required this.additionalNotes,
  });

  PrescriptionEntity copyWith({
    String? patientId,
    List<String>? diagnoses,
    List<MedicationItem>? medications,
    String? additionalNotes,
  }) {
    return PrescriptionEntity(
      patientId: patientId ?? this.patientId,
      diagnoses: diagnoses ?? this.diagnoses,
      medications: medications ?? this.medications,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  @override
  List<Object?> get props => [patientId, diagnoses, medications, additionalNotes];
}