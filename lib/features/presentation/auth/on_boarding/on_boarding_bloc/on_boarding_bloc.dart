import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'on_boarding_event.dart';
part 'on_boarding_state.dart';

class OnBoardingBloc extends Bloc<OnBoardingEvent, OnBoardingState> {
  OnBoardingBloc() : super(const OnBoardingState()) {

    // --- Weight Handlers ---

    on<UpdateWeightEvent>((event, emit) {
      emit(state.copyWith(currentWeight: event.weight));
    });

    on<ToggleUnitEvent>((event, emit) {
      if (state.currentUnit == event.unit) return;

      double convertedWeight;
      if (event.unit == "lbs") {
        convertedWeight = double.parse((state.currentWeight * 2.20462).toStringAsFixed(1));
      } else {
        convertedWeight = double.parse((state.currentWeight / 2.20462).toStringAsFixed(1));
      }

      emit(state.copyWith(
        currentWeight: convertedWeight,
        currentUnit: event.unit,
      ));
    });

    on<UpdateDOBEvent>((event, emit) {
      final age = DateTime.now().year - event.dob.year;
      emit(state.copyWith(selectedDob: event.dob, selectedAge: age));
    });
    on<UpdateHeightEvent>((event, emit) {
      emit(state.copyWith(currentHeight: event.height));
    });
    on<UpdateGenderEvent>((event, emit) {
      emit(state.copyWith(selectedGender: event.gender));
    });

    on<UpdateAgeEvent>((event, emit) {
      emit(state.copyWith(selectedAge: event.age));
    });
    on<ToggleHeightUnitEvent>((event, emit) {
      if (state.currentHeightUnit == event.unit) return;

      double convertedHeight;
      // Conversion logic: 1 inch = 2.54 cm
      if (event.unit == "in") {
        convertedHeight = double.parse((state.currentHeight / 2.54).toStringAsFixed(1));
      } else {
        convertedHeight = double.parse((state.currentHeight * 2.54).toStringAsFixed(1));
      }

      emit(state.copyWith(
        currentHeight: convertedHeight,
        currentHeightUnit: event.unit,
      ));
    });

    // --- API & Save Handlers ---

    on<SaveOnBoardingEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true, errorMessage: null, successMessage: null));
      try {
        // Implementation for Yiralife backend integration
        // await repository.saveHealthProfile(
        //   weight: state.currentWeight,
        //   height: state.currentHeight,
        //   date: event.date
        // );
        await Future.delayed(const Duration(seconds: 1));

        emit(state.copyWith(
          isLoading: false,
          successMessage: "Profile updated successfully",
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ));
      }
    });
  }
}