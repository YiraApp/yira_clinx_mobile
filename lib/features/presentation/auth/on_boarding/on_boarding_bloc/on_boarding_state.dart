part of 'on_boarding_bloc.dart';

@immutable
class OnBoardingState extends Equatable {
  // Weight Data
  final double currentWeight;
  final String currentUnit;

  // Height Data
  final double currentHeight;
  final String currentHeightUnit;

  // Gender & Age Data
  final String selectedGender;
  final int selectedAge;
  final DateTime? selectedDob;

  // New Blood Group Data
  final String selectedBloodGroup;

  // New Emergency Contact Data (Optional)
  final String selectedEmergencyRelation;

  // Status Data
  final bool isLoading;
  final bool isCompleted;
  final String? errorMessage;
  final String? successMessage;

  const OnBoardingState({
    this.currentWeight = 70.0,
    this.currentUnit = 'kgs',
    this.currentHeight = 170.0,
    this.currentHeightUnit = 'cm',
    this.selectedGender = "Male",
    this.selectedAge = 25,
    this.selectedDob,
    this.selectedBloodGroup = 'Select Blood Group',
    this.selectedEmergencyRelation = 'Select Relation Type',
    this.isLoading = false,
    this.isCompleted = false,
    this.errorMessage,
    this.successMessage,
  });

  OnBoardingState copyWith({
    double? currentWeight,
    String? currentUnit,
    double? currentHeight,
    String? currentHeightUnit,
    String? selectedGender,
    int? selectedAge,
    DateTime? selectedDob,
    String? selectedBloodGroup,
    String? selectedEmergencyRelation,
    bool? isLoading,
    bool? isCompleted,
    String? errorMessage,
    String? successMessage,
  }) {
    return OnBoardingState(
      currentWeight: currentWeight ?? this.currentWeight,
      currentUnit: currentUnit ?? this.currentUnit,
      currentHeight: currentHeight ?? this.currentHeight,
      currentHeightUnit: currentHeightUnit ?? this.currentHeightUnit,
      selectedGender: selectedGender ?? this.selectedGender,
      selectedAge: selectedAge ?? this.selectedAge,
      selectedDob: selectedDob ?? this.selectedDob,
      selectedBloodGroup: selectedBloodGroup ?? this.selectedBloodGroup,
      selectedEmergencyRelation: selectedEmergencyRelation ?? this.selectedEmergencyRelation,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
    currentWeight,
    currentUnit,
    currentHeight,
    currentHeightUnit,
    selectedGender,
    selectedAge,
    selectedDob,
    selectedBloodGroup,
    selectedEmergencyRelation,
    isLoading,
    isCompleted,
    errorMessage,
    successMessage,
  ];
}