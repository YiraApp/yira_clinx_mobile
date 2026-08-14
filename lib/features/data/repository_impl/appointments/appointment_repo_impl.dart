import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/local/cache/local_cache_data_source.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../../domain/repositories/appointments/appointment_repo.dart';
import '../../models/appointments/appointment_model.dart';

class AppointmentRepoImpl implements AppointmentRepo {
  final ApiClient _apiClient;
  final LocalCacheDataSource _localCache;
  final Connectivity _connectivity;

  AppointmentRepoImpl(
    this._apiClient,
    this._localCache, [
    Connectivity? connectivity,
  ]) : _connectivity = connectivity ?? Connectivity();

  @override
  Future<AppointmentDashboardDataModel?> fetchAppointmentDashboard({
    required String doctorId,
    required int orgId,
    required int hospitalId,
    String? status,
    String? search,
    String? date,
    String? dateFrom,
    String? dateTo,
  }) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final endPoint = URLs.appointmentDashboardUrl;
    final Map<String, dynamic> requestBody = {
      "doctorId": doctorId,
      "orgId": orgId,
      "hospitalId": hospitalId,
      if (status != null && status.isNotEmpty) "status": status,
      if (search != null && search.isNotEmpty) "search": search,
      if (date != null && date.isNotEmpty) "date": date,
      if (dateFrom != null && dateFrom.isNotEmpty) "dateFrom": dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) "dateTo": dateTo,
    };

    final String fullCacheKey = _generateDeterministicCacheKey(
      customPrefix: "appointmentDashboardKey",
      baseUrl: endPoint,
      params: requestBody,
    );

    final List<ConnectivityResult> connectivityResults =
        await _connectivity.checkConnectivity();
    final bool isHardwareOffline =
        connectivityResults.contains(ConnectivityResult.none);

    if (isHardwareOffline) {
      developer.log(
        "Offline detected. Reading appointment dashboard from SQLite cache.",
        name: "AppointmentRepoImpl",
      );
      return _fetchFromCacheKey(fullCacheKey);
    }

    try {
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account(showSuccessSnack: false).post(
        endPoint,
        data: requestBody,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> rawData =
            response.data as Map<String, dynamic>;

        final bool isSuccessStatus =
            rawData['status'] == true || rawData['success'] == true;

        if (isSuccessStatus) {
          await _localCache.saveResponse(fullCacheKey, jsonEncode(rawData));
          return AppointmentDashboardDataModel.fromJson(rawData);
        }
      }
    } on DioException catch (dioError) {
      developer.log(
        "Dio network error on appointment dashboard: ${dioError.type}",
        error: dioError,
        name: "AppointmentRepoImpl",
      );
    } catch (unexpectedError, stackTrace) {
      developer.log(
        "Unexpected error fetching appointment dashboard.",
        error: unexpectedError,
        stackTrace: stackTrace,
        name: "AppointmentRepoImpl",
      );
    }

    return _fetchFromCacheKey(fullCacheKey);
  }

  @override
  Future<bool> bookAppointment({
    required String doctorId,
    required int orgId,
    required int hospitalId,
    required String patientPhone,
    String? patientName,
    String? gender,
    String? dob,
    String? appointmentDate,
    String? startTime,
    String? reason,
    String? appointmentType,
    bool? isTeleConsultation,
  }) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final endPoint = URLs.bookAppointmentUrl;
    final Map<String, dynamic> requestBody = {
      "doctorId": doctorId,
      "orgId": orgId,
      "hospitalId": hospitalId,
      "patientPhone": patientPhone,
      if (patientName != null && patientName.isNotEmpty) "patientName": patientName,
      if (gender != null && gender.isNotEmpty) "gender": gender,
      if (dob != null && dob.isNotEmpty) "dob": dob,
      if (appointmentDate != null && appointmentDate.isNotEmpty) "appointmentDate": appointmentDate,
      if (startTime != null && startTime.isNotEmpty) "startTime": startTime,
      if (reason != null && reason.isNotEmpty) "reason": reason,
      if (appointmentType != null && appointmentType.isNotEmpty) "appointmentType": appointmentType,
      if (isTeleConsultation != null) "isTeleConsultation": isTeleConsultation,
    };

    try {
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account(showSuccessSnack: true).post(
        endPoint,
        data: requestBody,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final rawData = response.data as Map<String, dynamic>;
          if (rawData['status'] == false || rawData['success'] == false) {
            return false;
          }
        }
        return true;
      }
    } catch (e) {
      developer.log("Error booking appointment", error: e, name: "AppointmentRepoImpl");
    }
    return false;
  }

  @override
  Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final endPoint = URLs.updateAppointmentStatusUrl;
    final Map<String, dynamic> requestBody = {
      "appointmentId": appointmentId,
      "status": status,
    };

    try {
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account(showSuccessSnack: true).post(
        endPoint,
        data: requestBody,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final rawData = response.data as Map<String, dynamic>;
          if (rawData['status'] == false || rawData['success'] == false) {
            return false;
          }
        }
        return true;
      }
    } catch (e) {
      developer.log("Error updating appointment status", error: e, name: "AppointmentRepoImpl");
    }
    return false;
  }

  Future<AppointmentDashboardDataModel?> _fetchFromCacheKey(
      String cacheKey) async {
    try {
      final String? cachedJsonString =
          await _localCache.getCachedResponse(cacheKey);
      if (cachedJsonString != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedJsonString);
        return AppointmentDashboardDataModel.fromJson(decodedData);
      }
    } catch (cacheError, stackTrace) {
      developer.log(
        "Error fetching appointment dashboard from cache",
        error: cacheError,
        stackTrace: stackTrace,
        name: "AppointmentRepoImpl",
      );
    }
    return null;
  }

  String _generateDeterministicCacheKey({
    required String customPrefix,
    required String baseUrl,
    required Map<String, dynamic> params,
  }) {
    final sortedKeys = params.keys.toList()..sort();
    final String queryString = sortedKeys
        .map((key) => "$key=${Uri.encodeComponent(params[key].toString())}")
        .join('&');
    return "${customPrefix.trim()}#$baseUrl?$queryString";
  }
}
