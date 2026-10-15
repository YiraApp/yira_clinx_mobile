

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
    super.isFavorite,
    super.registeredDate,
  });

  // Convert JSON from API to Model
  factory PatientModel.fromJson(Map<String, dynamic> json, {bool isFavorite = false}) {
    String allergyStr = '';
    if (json['allergies'] is List) {
      allergyStr = (json['allergies'] as List).join(', ');
    } else if (json['allergies'] != null) {
      allergyStr = json['allergies'].toString();
    } else if (json['allergy'] != null) {
      allergyStr = json['allergy'].toString();
    }

    final bool fav = (json['isFavorite'] == true) || (json['is_favorite'] == true) || isFavorite;
    final String rawName = (json['name'] ?? json['patientName'] ?? json['firstName'] ?? '').toString().trim();
    final String fallbackPhone = (json['phoneNumber'] ?? json['phone'] ?? '').toString().trim();
    final String patientName = rawName.isNotEmpty ? rawName : (fallbackPhone.isNotEmpty ? fallbackPhone : 'Patient');

    DateTime? parsedRegDate;
    final rawRegDate = json['registeredDate'] ??
        json['registered_date'] ??
        json['createdAt'] ??
        json['created_at'] ??
        json['rawDate'] ??
        json['raw_date'];
    if (rawRegDate != null && rawRegDate.toString().trim().isNotEmpty) {
      parsedRegDate = DateTime.tryParse(rawRegDate.toString().trim())?.toLocal();
    }

    return PatientModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? json['id'] ?? '',
      name: patientName,
      condition: json['condition'] ?? '',
      lastVisit: json['last_visit_date'] ?? json['last_visit'] ?? '',
      status: json['status_label'] ?? json['status'] ?? '',
      gender: json['gender_label'] ?? json['gender'] ?? '',
      age: json['age'] ?? 0,
      visits: json['total_visits'] ?? json['visits'] ?? 0,
      allergy: allergyStr,
      isFavorite: fav,
      registeredDate: parsedRegDate,
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
      'isFavorite': isFavorite,
      'registeredDate': registeredDate?.toIso8601String(),
    };
  }
}