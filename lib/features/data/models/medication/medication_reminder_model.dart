import 'dart:convert';

class MedicationReminder {
  final String id;
  final String? prescriptionId;
  final String medicineName;
  final String dosage;
  final String instructions;
  final int durationDays;
  final bool isContinuous;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> timingSlots;
  final List<String> times; // e.g. ['08:00 AM', '10:30 AM', '01:00 PM', '04:00 PM', '08:00 PM']
  final String mealRelation; // 'After Food', 'Before Food', 'Anytime'
  final String doctorName;
  final String condition;
  final Map<String, bool> takenDoses; // e.g. {'2026-09-17_08:00 AM': true}
  final bool isActive;

  MedicationReminder({
    required this.id,
    this.prescriptionId,
    required this.medicineName,
    this.dosage = '',
    this.instructions = '',
    required this.durationDays,
    this.isContinuous = false,
    required this.startDate,
    required this.endDate,
    List<String>? timingSlots,
    required this.times,
    this.mealRelation = 'After Food',
    this.doctorName = '',
    this.condition = '',
    Map<String, bool>? takenDoses,
    this.isActive = true,
  })  : timingSlots = timingSlots ?? times,
        takenDoses = takenDoses ?? {};

  int get daysRemaining {
    if (isContinuous) return -1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final diff = end.difference(today).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  int get currentDayNumber {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final diff = today.difference(start).inDays + 1;
    if (diff < 1) return 1;
    if (!isContinuous && diff > durationDays) return durationDays;
    return diff;
  }

  bool isDoseTakenToday(String timeKey) {
    final now = DateTime.now();
    final key = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_$timeKey";
    return takenDoses[key] == true;
  }

  MedicationReminder copyWith({
    String? id,
    String? prescriptionId,
    String? medicineName,
    String? dosage,
    String? instructions,
    int? durationDays,
    bool? isContinuous,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? timingSlots,
    List<String>? times,
    String? mealRelation,
    String? doctorName,
    String? condition,
    Map<String, bool>? takenDoses,
    bool? isActive,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      durationDays: durationDays ?? this.durationDays,
      isContinuous: isContinuous ?? this.isContinuous,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timingSlots: timingSlots ?? this.timingSlots,
      times: times ?? this.times,
      mealRelation: mealRelation ?? this.mealRelation,
      doctorName: doctorName ?? this.doctorName,
      condition: condition ?? this.condition,
      takenDoses: takenDoses ?? Map<String, bool>.from(this.takenDoses),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prescriptionId': prescriptionId,
      'medicineName': medicineName,
      'dosage': dosage,
      'instructions': instructions,
      'durationDays': durationDays,
      'isContinuous': isContinuous,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'timingSlots': timingSlots,
      'times': times,
      'mealRelation': mealRelation,
      'doctorName': doctorName,
      'condition': condition,
      'takenDoses': takenDoses,
      'isActive': isActive,
    };
  }

  factory MedicationReminder.fromMap(Map<String, dynamic> map) {
    final timesList = List<String>.from(map['times'] ?? []);
    return MedicationReminder(
      id: map['id'] ?? '',
      prescriptionId: map['prescriptionId'],
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      instructions: map['instructions'] ?? '',
      durationDays: map['durationDays'] ?? 7,
      isContinuous: map['isContinuous'] ?? false,
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now().add(const Duration(days: 7)),
      timingSlots: List<String>.from(map['timingSlots'] ?? timesList),
      times: timesList,
      mealRelation: map['mealRelation'] ?? 'After Food',
      doctorName: map['doctorName'] ?? '',
      condition: map['condition'] ?? '',
      takenDoses: Map<String, bool>.from(map['takenDoses'] ?? {}),
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory MedicationReminder.fromJson(String source) => MedicationReminder.fromMap(json.decode(source));
}
