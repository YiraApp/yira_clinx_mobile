

import '../../../domain/entities/dashboard/patient_entity.dart';

class PatientModel extends PatientEntity {
  const PatientModel({
    required super.id,
    required super.name,
    required super.condition,
    required super.lastVisit,
    required super.status,
    required super.gender,
    required super.age,
    required super.visits,
    super.allergy,
  });

  // Convert JSON from API to Model
  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      condition: json['condition'] ?? '',
      lastVisit: json['last_visit'] ?? '',
      status: json['status'] ?? '',
      gender: json['gender'] ?? '',
      age: json['age'] ?? 0,
      visits: json['visits'] ?? 0,
      allergy: json['allergy'] ?? '',
    );
  }

  // Convert Model to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'condition': condition,
      'last_visit': lastVisit,
      'status': status,
      'gender': gender,
      'age': age,
      'visits': visits,
      'allergy': allergy,
    };
  }
}