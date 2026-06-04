
// domain/entities/medication_summary.dart
import 'package:equatable/equatable.dart';

class MedicationEntity extends Equatable {
  final int totalPrescriptions;
  final int activeMeds;
  final int totalMedications;
  final int needRefill;

  const MedicationEntity({
    required this.totalPrescriptions,
    required this.activeMeds,
    required this.totalMedications,
    required this.needRefill,
  });

  @override
  List<Object?> get props => [
    totalPrescriptions,
    activeMeds,
    totalMedications,
    needRefill,
  ];
}