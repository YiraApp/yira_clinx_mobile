import '../../../domain/entities/medicine/medical_history_entity.dart';

class MedicalRecordBriefModel extends MedicalRecordBriefEntity {
  const MedicalRecordBriefModel({
    required super.id,
    required super.title,
    required super.recordDate,
    required super.doctorName,
    required super.status,
    required super.chiefComplaint,
    required super.diagnosis,
    required super.vitalsSummary,
    super.symptoms,
    super.physicalExamination,
    super.treatmentPlan,
    super.bloodPressure,
    super.heartRate,
    super.temperature,
    super.weight,
    super.height,
  });

  factory MedicalRecordBriefModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    final rawDate = json['recordDate'] ?? json['record_date'] ?? json['CreatedAt'] ?? json['createdAt'];
    if (rawDate != null) {
      try {
        parsedDate = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    String docName = (json['doctorName'] ?? json['doctor_name'] ?? json['createdBy'] ?? '').toString();
    if (docName.isEmpty && json['Doctor'] is Map) {
      final docMap = json['Doctor'] as Map;
      docName = "Dr. ${docMap['FirstName'] ?? ''} ${docMap['LastName'] ?? ''}".trim();
    }
    if (docName.isEmpty) docName = 'Dr. Provider';

    final bp = json['BloodPressure'] ?? json['bloodPressure'];
    final hr = json['HeartRate'] ?? json['heartRate'];
    final temp = json['Temperature'] ?? json['temperature'];
    final weight = json['Weight'] ?? json['weight'];
    final height = json['Height'] ?? json['height'];

    String vitals = (json['vitalsSummary'] ?? json['vitals_summary'] ?? '').toString();
    if (vitals.isEmpty && (bp != null || hr != null || temp != null)) {
      final parts = <String>[];
      if (bp != null && bp.toString().isNotEmpty) parts.add("BP: $bp");
      if (hr != null && hr.toString().isNotEmpty) parts.add("HR: $hr");
      if (temp != null && temp.toString().isNotEmpty) parts.add("Temp: $temp");
      vitals = parts.join(", ");
    }

    return MedicalRecordBriefModel(
      id: (json['id'] ?? json['Id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      title: (json['title'] ?? json['Type'] ?? json['type'] ?? 'Consultation').toString(),
      recordDate: parsedDate,
      doctorName: docName,
      status: (json['status'] ?? json['Status'] ?? 'COMPLETED').toString(),
      chiefComplaint: (json['chiefComplaint'] ?? json['chief_complaint'] ?? json['ChiefComplaint'] ?? '').toString(),
      diagnosis: (json['diagnosis'] ?? json['Diagnosis'] ?? '').toString(),
      vitalsSummary: vitals,
      symptoms: (json['symptoms'] ?? json['Symptoms'] ?? '').toString(),
      physicalExamination: (json['physicalExamination'] ?? json['PhysicalExamination'] ?? json['examination'] ?? '').toString(),
      treatmentPlan: (json['treatmentPlan'] ?? json['Treatment'] ?? json['treatment'] ?? '').toString(),
      bloodPressure: bp?.toString() ?? '',
      heartRate: hr?.toString() ?? '',
      temperature: temp?.toString() ?? '',
      weight: weight?.toString() ?? '',
      height: height?.toString() ?? '',
    );
  }
}