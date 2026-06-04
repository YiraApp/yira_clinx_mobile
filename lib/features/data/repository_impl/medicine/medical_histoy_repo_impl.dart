
import '../../../domain/entities/medicine/medical_history_entity.dart';
import '../../../domain/repositories/medicine/medical_history_repo.dart';
import '../../models/medicine/medical_history_model.dart';

class MedicalHistoryRepositoryImpl implements MedicalHistoryRepository {
  @override
  Future<List<MedicalRecordBriefEntity>> fetchMedicalRecords() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
    MedicalRecordBriefModel(
        id: "1",
        title: "consultation",
        recordDate:   DateTime(2026, 5, 27),
    doctorName: "Dr. bhargav c",
    status: "COMPLETED",
    chiefComplaint: "Headache, Allergic rhinitis caused by pollen",
    diagnosis: "Ketoacidotic coma due to diabetes mellitus",
    vitalsSummary: "BP: 145/90, HR: 74, Temp: 99",
    ),
     MedicalRecordBriefModel(
    id: "2",
    title: "consultation",
    recordDate:  DateTime(2026, 5, 27),
    doctorName: "Dr. bhargav c",
    status: "COMPLETED",
    chiefComplaint: "Fever, Dry cough",
    diagnosis: "Hypermetropia, Hyperoxia, Desert sore",
    vitalsSummary: "BP: 145/90, HR: 74, Temp: 99",
    )
    ];
  }

  @override
  Future<void> deleteMedicalRecord(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}