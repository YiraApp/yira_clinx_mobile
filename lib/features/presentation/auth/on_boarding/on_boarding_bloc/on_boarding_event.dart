part of 'on_boarding_bloc.dart';

@immutable
abstract class OnBoardingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Triggered when user scrolls the ruler
class UpdateWeightEvent extends OnBoardingEvent {
  final double weight;
  UpdateWeightEvent(this.weight);
  @override
  List<Object?> get props => [weight];
}

// Triggered when user clicks KGS or LBS
class UpdateHeightEvent extends OnBoardingEvent {
  final double height;
  UpdateHeightEvent(this.height);
}

class ToggleHeightUnitEvent extends OnBoardingEvent {
  final String unit; // 'cm' or 'in'
  ToggleHeightUnitEvent(this.unit);
}
class ToggleUnitEvent extends OnBoardingEvent {
  final String unit;
  ToggleUnitEvent(this.unit);
  @override
  List<Object?> get props => [unit];
}

class SaveOnBoardingEvent extends OnBoardingEvent {
  final String date;
  SaveOnBoardingEvent({required this.date});
}
class UpdateGenderEvent extends OnBoardingEvent {
  final String gender;
  UpdateGenderEvent(this.gender);
}

class UpdateAgeEvent extends OnBoardingEvent {
  final int age;
  UpdateAgeEvent(this.age);
}
class UpdateDOBEvent extends OnBoardingEvent {
  final DateTime dob;
  UpdateDOBEvent(this.dob);
}
class UpdateBloodGroupEvent extends OnBoardingEvent {
  final String bloodGroup;

  UpdateBloodGroupEvent(this.bloodGroup);

  @override
  List<Object?> get props => [bloodGroup];
}

class UpdateEmergencyRelationEvent extends OnBoardingEvent {
  final String relation;

  UpdateEmergencyRelationEvent(this.relation);

  @override
  List<Object?> get props => [relation];
}