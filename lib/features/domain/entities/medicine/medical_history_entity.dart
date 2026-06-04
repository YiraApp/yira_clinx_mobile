
import 'package:equatable/equatable.dart';

class MedicalRecordBriefEntity extends Equatable {
  final String id;
  final String title;
  final DateTime recordDate;
  final String doctorName;
  final String status;
  final String chiefComplaint;
  final String diagnosis;
  final String vitalsSummary;

  const MedicalRecordBriefEntity({
    required this.id,
    required this.title,
    required this.recordDate,
    required this.doctorName,
    required this.status,
    required this.chiefComplaint,
    required this.diagnosis,
    required this.vitalsSummary,
  });

  @override
  List<Object?> get props => [id, title, recordDate, doctorName, status, chiefComplaint, diagnosis, vitalsSummary];
}