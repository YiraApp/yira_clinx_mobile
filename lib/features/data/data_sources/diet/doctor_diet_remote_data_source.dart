import 'dart:io';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';

/// Diet calls a doctor makes about one patient (the Diet tab). Every call
/// throws on failure; use [dietApiErrorMessage] to show why.
class DoctorDietRemoteDataSource {
  final ApiClient _apiClient;

  DoctorDietRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Options _options(String? orgId) {
    final user = GlobalSession.instance.userNotifier.value?.data;
    final token = user?.accessToken ?? '';
    final org = (orgId ?? '').isNotEmpty ? orgId! : (user?.latestOrgId?.toString() ?? '');
    return Options(
      extra: dietQuietErrors,
      headers: {
        if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
        if (org.isNotEmpty) 'x-org-id': org,
      },
    );
  }

  /// Plans prescribed to [patientId] in the doctor's organization, newest first.
  /// With [fullHistory] (needs the patient's consent) every plan they have,
  /// from any organization and including ones they made themselves.
  Future<List<Map<String, dynamic>>> getPatientPlans(String patientId, {String? orgId, bool fullHistory = false}) async {
    final response = await _apiClient.account(showSuccessSnack: false).get(
          '${URLs.doctorDietPatientPlansUrl}/$patientId/plans',
          queryParameters: fullHistory ? const {'scope': 'all'} : null,
          options: _options(orgId),
        );
    final data = response.data;
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// One plan with all of its meals.
  Future<Map<String, dynamic>> getPlan(int planId, {String? orgId, bool fullHistory = false}) async {
    final response = await _apiClient.account(showSuccessSnack: false).get(
          '${URLs.doctorDietPlanUrl}/$planId',
          queryParameters: fullHistory ? const {'scope': 'all'} : null,
          options: _options(orgId),
        );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Saves a doctor's changes to a prescribed plan (details and meals).
  Future<Map<String, dynamic>> updatePlan(int planId, Map<String, dynamic> payload, {String? orgId}) async {
    final response = await _apiClient.account(showSuccessSnack: false).put(
          '${URLs.doctorDietPlanUrl}/$planId',
          data: payload,
          options: _options(orgId),
        );
    return response.data is Map ? Map<String, dynamic>.from(response.data as Map) : <String, dynamic>{};
  }

  /// active / paused / completed / cancelled.
  Future<void> setPlanStatus(int planId, String status, {String? orgId}) async {
    await _apiClient.account(showSuccessSnack: false).patch(
          '${URLs.doctorDietPlanUrl}/$planId/status',
          data: {'status': status},
          options: _options(orgId),
        );
  }
}
