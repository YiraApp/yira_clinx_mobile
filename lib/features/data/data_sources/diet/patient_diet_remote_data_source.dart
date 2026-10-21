import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';
import 'package:yiraclinics/features/data/models/diet/patient_diet_plan_model.dart';

class PatientDietRemoteDataSource {
  final ApiClient _apiClient;

  PatientDietRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch today's meals with macro calculations and prescribed schedule
  Future<TodayDietResponse?> getTodayDiet({String? patientId}) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      final pid = (patientId != null && patientId.isNotEmpty)
          ? patientId
          : (currentUser?.data?.id ?? '');

      final queryParams = <String, dynamic>{};
      if (pid.isNotEmpty) {
        queryParams['patientId'] = pid;
      }

      final response = await _apiClient.account(showSuccessSnack: false).get(
        URLs.patientDietTodayUrl,
        queryParameters: queryParams,
        options: Options(
          headers: {
            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        return TodayDietResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint("PatientDietRemoteDataSource getTodayDiet error: $e");
      return null;
    }
  }

  /// Fetch active plan overview
  Future<Map<String, dynamic>?> getActivePlan({String? patientId}) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      final pid = (patientId != null && patientId.isNotEmpty)
          ? patientId
          : (currentUser?.data?.id ?? '');

      final queryParams = <String, dynamic>{};
      if (pid.isNotEmpty) {
        queryParams['patientId'] = pid;
      }

      final response = await _apiClient.account(showSuccessSnack: false).get(
        URLs.patientDietActivePlanUrl,
        queryParameters: queryParams,
        options: Options(
          headers: {
            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("PatientDietRemoteDataSource getActivePlan error: $e");
      return null;
    }
  }

  /// Fetch full plan with all days and meals
  Future<Map<String, dynamic>?> getPlanDetails(int planId) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account(showSuccessSnack: false).get(
        '${URLs.patientDietPlanDetailsUrl}/$planId',
        options: Options(
          headers: {
            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint("PatientDietRemoteDataSource getPlanDetails error: $e");
      return null;
    }
  }

  /// Saves the signed-in patient's changes to their active plan and returns
  /// the updated plan. Throws on failure; use [dietApiErrorMessage] to show why.
  Future<Map<String, dynamic>> updateMyPlan(int planId, List<Map<String, dynamic>> meals) async {
    final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';

    final response = await _apiClient.account(showSuccessSnack: false).put(
      '${URLs.patientDietUpdateMyPlanUrl}/$planId',
      data: {'meals': meals},
      options: Options(
        extra: dietQuietErrors,
        headers: {
          if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
        },
      ),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response while saving the diet plan.');
  }

  Options _quietOptions() {
    final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
    return Options(
      extra: dietQuietErrors,
      headers: {
        if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
      },
    );
  }

  /// Every plan prescribed to the signed-in patient, the active one first.
  /// Throws on failure; use [dietApiErrorMessage] to show why.
  Future<List<PatientDietPlanSummary>> getMyPlans() async {
    final response = await _apiClient.account(showSuccessSnack: false).get(
          URLs.patientDietMyPlansUrl,
          options: _quietOptions(),
        );
    final data = response.data;
    final list = data is List ? data : (data is Map && data['data'] is List ? data['data'] as List : const []);
    return list
        .whereType<Map>()
        .map((e) => PatientDietPlanSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Turns a plan on ("active") or off ("paused"). Returns the server's message.
  Future<String> setMyPlanStatus(int planId, String status) async {
    final response = await _apiClient.account(showSuccessSnack: false).put(
          '${URLs.patientDietMyPlansUrl}/$planId/status',
          data: {'status': status},
          options: _quietOptions(),
        );
    final data = response.data;
    return data is Map && data['message'] != null
        ? data['message'].toString()
        : (status == 'active' ? 'Diet plan activated.' : 'Diet plan paused.');
  }

  /// The patient's meal records for [planId] between two dates (inclusive).
  Future<List<DietMealLog>> getMealLogs(int planId, DateTime from, DateTime to) async {
    final response = await _apiClient.account(showSuccessSnack: false).get(
          '${URLs.patientDietMyPlansUrl}/$planId/logs',
          queryParameters: {'from': dietDateKey(from), 'to': dietDateKey(to)},
          options: _quietOptions(),
        );
    final data = response.data;
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => DietMealLog.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Marks a food as eaten (or not) on [date].
  Future<DietMealLog> saveMealLog({
    required int planId,
    required int planMealId,
    required DateTime date,
    required bool isEaten,
  }) async {
    final response = await _apiClient.account(showSuccessSnack: false).put(
          '${URLs.patientDietMyPlansUrl}/$planId/logs',
          data: {'planMealId': planMealId, 'date': dietDateKey(date), 'isEaten': isEaten},
          options: _quietOptions(),
        );
    return DietMealLog.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// Removes the photo of a food on [date]; whether it was eaten is kept.
  Future<DietMealLog> removeMealPhoto({
    required int planId,
    required int planMealId,
    required DateTime date,
  }) async {
    final response = await _apiClient.account(showSuccessSnack: false).put(
          '${URLs.patientDietMyPlansUrl}/$planId/logs',
          data: {'planMealId': planMealId, 'date': dietDateKey(date), 'removePhoto': true},
          options: _quietOptions(),
        );
    return DietMealLog.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// Uploads a photo of a food the patient ate on [date]; it also marks it eaten.
  Future<DietMealLog> uploadMealPhoto({
    required int planId,
    required int planMealId,
    required DateTime date,
    required String filePath,
  }) async {
    final name = filePath.split(Platform.pathSeparator).last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
    final subtype = switch (ext) {
      'png' => 'png',
      'webp' => 'webp',
      'heic' => 'heic',
      'heif' => 'heif',
      _ => 'jpeg',
    };
    final form = FormData.fromMap({
      'planMealId': planMealId.toString(),
      'date': dietDateKey(date),
      'photo': await MultipartFile.fromFile(
        filePath,
        filename: name,
        contentType: DioMediaType('image', subtype),
      ),
    });
    final response = await _apiClient.account(showSuccessSnack: false).post(
          '${URLs.patientDietMyPlansUrl}/$planId/logs/photo',
          data: form,
          options: _quietOptions(),
        );
    return DietMealLog.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// Creates a plan the patient made for themselves. Returns the full plan.
  Future<Map<String, dynamic>> createMyPlan(Map<String, dynamic> payload) async {
    final response = await _apiClient.account(showSuccessSnack: false).post(
          URLs.patientDietMyPlansUrl,
          data: payload,
          options: _quietOptions(),
        );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Unexpected response while creating the diet plan.');
  }

  /// Deletes a plan the patient made. Prescribed plans can't be deleted.
  Future<void> deleteMyPlan(int planId) async {
    await _apiClient.account(showSuccessSnack: false).delete(
          '${URLs.patientDietMyPlansUrl}/$planId',
          options: _quietOptions(),
        );
  }
}
