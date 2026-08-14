import '../../../domain/entities/prescriptions/prescription_entity.dart';
import '../../../domain/entities/prescriptions/prescription_item.dart';

class PrescriptionModel extends PrescriptionEntity {
  const PrescriptionModel({
    required super.patientId,
    super.appointmentId,
    super.hospitalId,
    super.orgId,
    required super.diagnoses,
    required super.medications,
    required super.additionalNotes,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    // Diagnoses list handling
    List<String> parsedDiagnoses = [];
    if (json['diagnoses'] is List) {
      parsedDiagnoses = (json['diagnoses'] as List).map((e) {
        if (e is Map) return (e['Diagnosis'] ?? e['diagnosis'] ?? '').toString();
        return e.toString();
      }).where((s) => s.isNotEmpty).toList();
    } else if (json['Diagnoses'] is List) {
      parsedDiagnoses = (json['Diagnoses'] as List).map((e) {
        if (e is Map) return (e['Diagnosis'] ?? e['diagnosis'] ?? '').toString();
        return e.toString();
      }).where((s) => s.isNotEmpty).toList();
    }

    // Medications list handling
    List<MedicationItem> parsedMedications = [];
    final rawMeds = json['medications'] ?? json['Medications'];
    if (rawMeds is List) {
      parsedMedications = rawMeds
          .whereType<Map<String, dynamic>>()
          .map((e) => MedicationItemModel.fromJson(e))
          .toList();
    }

    return PrescriptionModel(
      patientId: (json['patientId'] ?? json['patient_id'] ?? json['PatientId'] ?? '').toString(),
      appointmentId: (json['appointmentId'] ?? json['appointment_id'] ?? json['AppointmentId'])?.toString(),
      hospitalId: (json['hospitalId'] ?? json['hospital_id'] ?? json['HospitalId'])?.toString(),
      orgId: (json['orgId'] ?? json['org_id'] ?? json['OrganizationId'])?.toString(),
      diagnoses: parsedDiagnoses,
      medications: parsedMedications,
      additionalNotes: (json['additionalNotes'] ?? json['additional_notes'] ?? json['Notes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'hospital_id': hospitalId,
      'org_id': orgId,
      'diagnoses': diagnoses,
      'medications': medications.map((m) => MedicationItemModel.fromEntity(m).toJson()).toList(),
      'additional_notes': additionalNotes,
    };
  }
}

class MedicationItemModel extends MedicationItem {
  const MedicationItemModel({
    required super.id,
    required super.name,
    super.dosage,
    super.frequency,
    super.duration,
    super.route,
  });

  factory MedicationItemModel.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? json['medication'] ?? json['Medication'] ?? '').toString();
    final dosage = (json['dosage'] ?? json['Dosage'])?.toString();
    final frequency = (json['frequency'] ?? json['FrequencyType'] ?? json['frequencyType'])?.toString();

    String? duration = (json['duration'] ?? json['Duration'])?.toString();
    if (duration == null && json['DurationValue'] != null) {
      final unit = (json['DurationUnit'] ?? 'Days').toString();
      duration = "${json['DurationValue']} $unit";
    }

    final route = (json['route'] ?? json['Route'])?.toString();
    final id = (json['id'] ?? json['Id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString();

    return MedicationItemModel(
      id: id,
      name: name,
      dosage: dosage,
      frequency: frequency,
      duration: duration,
      route: route,
    );
  }

  factory MedicationItemModel.fromEntity(MedicationItem entity) {
    return MedicationItemModel(
      id: entity.id,
      name: entity.name,
      dosage: entity.dosage,
      frequency: entity.frequency,
      duration: entity.duration,
      route: entity.route,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'route': route,
    };
  }
}