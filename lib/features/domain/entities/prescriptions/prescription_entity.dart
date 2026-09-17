import 'package:equatable/equatable.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_item.dart';

class PrescriptionEntity extends Equatable {
  final String? id;
  final String patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final List<String> diagnoses;
  final List<MedicationItem> medications;
  final String additionalNotes;
  final String? pdfUrl;

  const PrescriptionEntity({
    this.id,
    required this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    required this.diagnoses,
    required this.medications,
    required this.additionalNotes,
    this.pdfUrl,
  });

  PrescriptionEntity copyWith({
    String? id,
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
    List<String>? diagnoses,
    List<MedicationItem>? medications,
    String? additionalNotes,
    String? pdfUrl,
  }) {
    return PrescriptionEntity(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      hospitalId: hospitalId ?? this.hospitalId,
      orgId: orgId ?? this.orgId,
      diagnoses: diagnoses ?? this.diagnoses,
      medications: medications ?? this.medications,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        appointmentId,
        hospitalId,
        orgId,
        diagnoses,
        medications,
        additionalNotes,
        pdfUrl,
      ];
}