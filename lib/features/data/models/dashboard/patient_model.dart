

import '../../../domain/entities/dashboard/patient_entity.dart';

class PatientModel extends PatientEntity {
  const PatientModel({
    required super.id,
    required super.userId,
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
    String allergyStr = '';
    if (json['allergies'] is List) {
      allergyStr = (json['allergies'] as List).join(', ');
    } else if (json['allergies'] != null) {
      allergyStr = json['allergies'].toString();
    } else if (json['allergy'] != null) {
      allergyStr = json['allergy'].toString();
    }

    return PatientModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      condition: json['condition'] ?? '',
      lastVisit: json['last_visit_date'] ?? json['last_visit'] ?? '',
      status: json['status_label'] ?? json['status'] ?? '',
      gender: json['gender_label'] ?? json['gender'] ?? '',
      age: json['age'] ?? 0,
      visits: json['total_visits'] ?? json['visits'] ?? 0,
      allergy: allergyStr,
    );
  }

  // Convert Model to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
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