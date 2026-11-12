import 'package:equatable/equatable.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/lab_test_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_item.dart';

class PrescriptionEntity extends Equatable {
  final String? id;
  final String patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  /// The medical record printed on the prescription PDF (else the visit's latest record).
  final String? medicalRecordId;
  final List<String> diagnoses;
  final List<MedicationItem> medications;
  final String additionalNotes;
  final String? pdfUrl;

  /// On a save, a list replaces the prescription's tests and null leaves them.
  final List<PrescribedLabTest>? labTests;

  const PrescriptionEntity({
    this.id,
    required this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    this.medicalRecordId,
    required this.diagnoses,
    required this.medications,
    required this.additionalNotes,
    this.pdfUrl,
    this.labTests,
  });

  PrescriptionEntity copyWith({
    String? id,
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
    String? medicalRecordId,
    List<String>? diagnoses,
    List<MedicationItem>? medications,
    String? additionalNotes,
    String? pdfUrl,
    List<PrescribedLabTest>? labTests,
  }) {
    return PrescriptionEntity(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      hospitalId: hospitalId ?? this.hospitalId,
      orgId: orgId ?? this.orgId,
      medicalRecordId: medicalRecordId ?? this.medicalRecordId,
      diagnoses: diagnoses ?? this.diagnoses,
      medications: medications ?? this.medications,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      labTests: labTests ?? this.labTests,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        appointmentId,
        hospitalId,
        orgId,
        medicalRecordId,
        diagnoses,
        medications,
        additionalNotes,
        pdfUrl,
        labTests,
      ];
}