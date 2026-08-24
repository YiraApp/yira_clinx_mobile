

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
  final bool? isFavoriteRaw;

  bool get isFavorite => isFavoriteRaw ?? false;

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
    bool? isFavorite,
  }) : isFavoriteRaw = isFavorite ?? false;

  PatientEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? condition,
    String? lastVisit,
    String? status,
    String? gender,
    String? allergy,
    int? age,
    int? visits,
    bool? isFavorite,
  }) {
    return PatientEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      condition: condition ?? this.condition,
      lastVisit: lastVisit ?? this.lastVisit,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      allergy: allergy ?? this.allergy,
      age: age ?? this.age,
      visits: visits ?? this.visits,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, status, condition, isFavorite];
}