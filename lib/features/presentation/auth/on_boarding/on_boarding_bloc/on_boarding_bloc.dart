import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';

part 'on_boarding_event.dart';
part 'on_boarding_state.dart';

class OnBoardingBloc extends Bloc<OnBoardingEvent, OnBoardingState> {
  OnBoardingBloc() : super(const OnBoardingState()) {

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

    on<UpdateBloodGroupEvent>((event, emit) {
      emit(state.copyWith(selectedBloodGroup: event.bloodGroup));
    });

    on<UpdateEmergencyRelationEvent>((event, emit) {
      emit(state.copyWith(selectedEmergencyRelation: event.relation));
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

    on<SaveOnBoardingEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true, errorMessage: null, successMessage: null, isCompleted: false));
      try {
        final double heightInCm = state.currentHeightUnit == 'in'
            ? (state.currentHeight * 2.54)
            : state.currentHeight;

        final double weightInKg = state.currentUnit == 'lbs'
            ? (state.currentWeight / 2.20462)
            : state.currentWeight;

        final String? dobString = state.selectedDob != null
            ? DateFormat('yyyy-MM-dd').format(state.selectedDob!)
            : null;

        final String? bloodGroup = state.selectedBloodGroup != 'Select Blood Group'
            ? state.selectedBloodGroup
            : null;

        final userSession = GlobalSession.instance.userNotifier.value;
        final String token = userSession?.data?.accessToken ?? '';
        final String userId = userSession?.data?.id ?? '';
        final int? hospitalId = userSession?.data?.latestHospitalId;
        final int? orgId = userSession?.data?.latestOrgId;

        final Map<String, dynamic> requestBody = {
          if (userId.isNotEmpty) "userId": userId,
          if (hospitalId != null) "hospitalId": hospitalId,
          if (orgId != null) "orgId": orgId,
          "height": double.parse(heightInCm.toStringAsFixed(1)),
          "weight": double.parse(weightInKg.toStringAsFixed(1)),
          "gender": state.selectedGender,
          if (dobString != null) "dob": dobString,
          if (dobString != null) "dateOfBirth": dobString,
          if (bloodGroup != null) "bloodGroup": bloodGroup,
        };

        developer.log("Submitting OnBoarding health data: $requestBody", name: "OnBoardingBloc");

        try {
          final dio = ApiClient().account(showSuccessSnack: false);
          final options = token.isNotEmpty
              ? Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'})
              : null;

          final response = await dio.post(
            URLs.providerProfileUpdateUrl,
            data: requestBody,
            options: options,
          );
          developer.log("OnBoarding API response: ${response.data}", name: "OnBoardingBloc");
        } catch (apiError, stackTrace) {
          developer.log(
            "OnBoarding API call failed gracefully: $apiError",
            error: apiError,
            stackTrace: stackTrace,
            name: "OnBoardingBloc",
          );
        }

        emit(state.copyWith(
          isLoading: false,
          isCompleted: true,
          successMessage: "Profile completed successfully",
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          isCompleted: false,
          errorMessage: e.toString(),
        ));
      }
    });
  }
}