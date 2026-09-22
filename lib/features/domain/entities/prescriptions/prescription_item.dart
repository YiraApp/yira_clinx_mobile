

import 'package:equatable/equatable.dart';

class MedicationItem extends Equatable {
  final String id;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;
  final String? route;
  final String? instructions;

  const MedicationItem({
    required this.id,
    required this.name,
    this.dosage,
    this.frequency,
    this.duration,
    this.route,
    this.instructions,
  });

  /// Alias for instructions / note
  String? get note => instructions;

  MedicationItem copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? route,
    String? instructions,
  }) {
    return MedicationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      route: route ?? this.route,
      instructions: instructions ?? this.instructions,
    );
  }

  @override
  List<Object?> get props => [id, name, dosage, frequency, duration, route, instructions];
}