

// domain/entities/patient_entity.dart
import 'package:equatable/equatable.dart';

class PatientEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String condition;
  final String lastVisit;
  final String status;
  final String gender;
  final String allergy;
  final int age;
  final int visits;

  const PatientEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.condition,
    required this.lastVisit,
    required this.status,
    required this.gender,
    required this.visits,
    required this.age,
    this.allergy = "",
  });

  @override
  List<Object?> get props => [id, userId, name, status, condition];
}