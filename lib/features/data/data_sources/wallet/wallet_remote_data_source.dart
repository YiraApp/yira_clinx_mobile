import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../../../di/dependency_injection.dart';
import '../../models/wallet/wallet_models.dart';

/// My billing and My policies for the open profile. Errors are thrown as-is;
/// use [walletErrorMessage] to show why.
class WalletRemoteDataSource {
  WalletRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient;

  final ApiClient? _apiClient;

  ApiClient get _api => _apiClient ?? sl<ApiClient>();

  String get _patientId => GlobalSession.instance.userNotifier.value?.data?.id ?? '';

  Options _options() {
    final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
    return Options(
      extra: const {'suppressErrorSnack': true},
      headers: {if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
  }

  Map<String, dynamic> _data(Response res) {
    final body = res.data;
    final data = body is Map ? body['data'] : null;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected response');
  }

  /// Fields plus an optional photo or PDF as one multipart form.
  Future<FormData> _form(Map<String, dynamic> fields, String? filePath) async {
    final form = FormData.fromMap({
      'patientId': _patientId,
      for (final e in fields.entries)
        if (e.value != null) e.key: e.value.toString(),
    });
    if (filePath != null) {
      final name = filePath.split(Platform.pathSeparator).last;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      final type = switch (ext) {
        'pdf' => DioMediaType('application', 'pdf'),
        'png' => DioMediaType('image', 'png'),
        'webp' => DioMediaType('image', 'webp'),
        'heic' || 'heif' => DioMediaType('image', ext),
        _ => DioMediaType('image', 'jpeg'),
      };
      form.files.add(MapEntry('file', await MultipartFile.fromFile(filePath, filename: name, contentType: type)));
    }
    return form;
  }

  Future<BillingData> getBilling() async {
    final res = await _api.account(showSuccessSnack: false).get(
          URLs.patientBillingUrl,
          queryParameters: {'patientId': _patientId},
          options: _options(),
        );
    return BillingData.fromJson(_data(res));
  }

  /// Adds a bill, or updates the one with [id] (only bills the patient added).
  Future<BillEntry> saveBill(Map<String, dynamic> fields, {String? id, String? filePath}) async {
    final form = await _form(fields, filePath);
    final client = _api.account(showSuccessSnack: false);
    final res = id == null
        ? await client.post(URLs.patientBillingUrl, data: form, options: _options())
        : await client.put('${URLs.patientBillingUrl}/$id', data: form, options: _options());
    return BillEntry.fromJson(_data(res));
  }

  Future<void> deleteBill(String id) async {
    await _api.account(showSuccessSnack: false).delete(
          '${URLs.patientBillingUrl}/$id',
          queryParameters: {'patientId': _patientId},
          options: _options(),
        );
  }

  Future<List<PolicyEntry>> getPolicies() async {
    final res = await _api.account(showSuccessSnack: false).get(
          URLs.patientPoliciesUrl,
          queryParameters: {'patientId': _patientId},
          options: _options(),
        );
    final list = _data(res)['policies'];
    return (list is List ? list : const [])
        .whereType<Map>()
        .map((e) => PolicyEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PolicyEntry> savePolicy(Map<String, dynamic> fields, {String? id, String? filePath}) async {
    final form = await _form(fields, filePath);
    final client = _api.account(showSuccessSnack: false);
    final res = id == null
        ? await client.post(URLs.patientPoliciesUrl, data: form, options: _options())
        : await client.put('${URLs.patientPoliciesUrl}/$id', data: form, options: _options());
    return PolicyEntry.fromJson(_data(res));
  }

  Future<void> deletePolicy(String id) async {
    await _api.account(showSuccessSnack: false).delete(
          '${URLs.patientPoliciesUrl}/$id',
          queryParameters: {'patientId': _patientId},
          options: _options(),
        );
  }
}

/// The server's message, or [fallback] (for example when offline).
String walletErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    // The server answers 404 with an HTML or "Cannot GET" page when it runs a
    // build from before My billing and My policies existed.
    if (error.response?.statusCode == 404 && error.response?.data is! Map) {
      return 'This needs the latest server update, which isn\'t live yet. It will work as soon as the update is deployed.';
    }
    final data = error.response?.data;
    if (data is Map) {
      final message = (data['message'] ?? data['error'])?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
      return 'No connection. Check your internet and try again.';
    }
  }
  return fallback;
}
