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
  final DateTime? selectedDob; // Added for DOB Selection

  // Status Data
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const OnBoardingState({
    this.currentWeight = 70.0,
    this.currentUnit = 'kgs',
    this.currentHeight = 170.0,
    this.currentHeightUnit = 'cm',
    this.selectedGender = "Male",
    this.selectedAge = 25,
    this.selectedDob, // Default will be set in Bloc or remain null until picked
    this.isLoading = false,
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
    DateTime? selectedDob, // Added to copyWith
    bool? isLoading,
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
      selectedDob: selectedDob ?? this.selectedDob, // Support for DOB update
      isLoading: isLoading ?? false,
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
    selectedDob, // Added to Equatable props
    isLoading,
    errorMessage,
    successMessage,
  ];
}