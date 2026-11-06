import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../../../di/dependency_injection.dart';
import '../../models/questionnaires/questionnaire_models.dart';

/// Questionnaires for the open profile, and a patient's answers for their doctor.
/// Errors are thrown as-is; [questionnaireErrorMessage] says why.
class QuestionnaireRemoteDataSource {
  QuestionnaireRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient;

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

  dynamic _data(Response res) {
    final body = res.data;
    if (body is Map && body.containsKey('data')) return body['data'];
    throw Exception('Unexpected response');
  }

  Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : throw Exception('Unexpected response');

  /// The list, due ones first, and how many are due.
  Future<({List<PatientQuestionnaire> items, int dueCount})> list() async {
    final res = await _api.account(showSuccessSnack: false).get(
          URLs.patientQuestionnairesUrl,
          queryParameters: {'patientId': _patientId},
          options: _options(),
        );
    final data = _map(_data(res));
    final items = (data['items'] is List ? data['items'] as List : const [])
        .whereType<Map>()
        .map((e) => PatientQuestionnaire.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final due = data['dueCount'];
    return (items: items, dueCount: due is int ? due : items.where((q) => q.state == QuestionnaireState.due).length);
  }

  Future<QuestionnaireForm> form(int id) async {
    final res = await _api.account(showSuccessSnack: false).get(
          '${URLs.patientQuestionnairesUrl}/$id',
          queryParameters: {'patientId': _patientId},
          options: _options(),
        );
    return QuestionnaireForm.fromJson(_map(_data(res)));
  }

  Future<QuestionnaireSubmission> submit(int id, List<Map<String, dynamic>> answers) async {
    final res = await _api.account(showSuccessSnack: false).post(
          '${URLs.patientQuestionnairesUrl}/$id/submit',
          data: {'patientId': _patientId, 'answers': answers},
          options: _options(),
        );
    return QuestionnaireSubmission.fromJson(_map(_data(res)));
  }

  Future<QuestionnaireSubmission> submission(int id) async {
    final res = await _api.account(showSuccessSnack: false).get(
          '${URLs.patientQuestionnaireSubmissionsUrl}/$id',
          queryParameters: {'patientId': _patientId},
          options: _options(),
        );
    return QuestionnaireSubmission.fromJson(_map(_data(res)));
  }

  /// A patient's answers for their doctor. With [hospitalId] or [appointmentId]
  /// it's that hospital's questionnaires; without, it needs the patient's consent.
  Future<List<DoctorQuestionnaireGroup>> forDoctor(String patientId, {String? hospitalId, String? appointmentId}) async {
    final res = await _api.account(showSuccessSnack: false).get(
          URLs.doctorPatientQuestionnairesUrl(patientId),
          queryParameters: {
            if ((hospitalId ?? '').isNotEmpty && hospitalId != '0') 'hospitalId': hospitalId,
            if ((appointmentId ?? '').isNotEmpty && appointmentId != '0') 'appointmentId': appointmentId,
          },
          options: _options(),
        );
    final data = _data(res);
    return (data is List ? data : const [])
        .whereType<Map>()
        .map((e) => DoctorQuestionnaireGroup.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// The hospital's published questionnaires for this patient, for a doctor choosing one to send.
  Future<List<SendableQuestionnaire>> sendable(String patientId, {required String hospitalId}) async {
    final res = await _api.account(showSuccessSnack: false).get(
          URLs.doctorSendableQuestionnairesUrl(patientId),
          queryParameters: {'hospitalId': hospitalId},
          options: _options(),
        );
    final data = _map(_data(res));
    return (data['questionnaires'] is List ? data['questionnaires'] as List : const [])
        .whereType<Map>()
        .map((e) => SendableQuestionnaire.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Sends one questionnaire to this patient; they get a notification.
  Future<void> sendToPatient(String patientId, int questionnaireId, {required String hospitalId, int? dueInDays}) async {
    await _api.account(showSuccessSnack: false).post(
          URLs.doctorSendQuestionnaireUrl(patientId, questionnaireId),
          data: {'hospitalId': int.tryParse(hospitalId) ?? hospitalId, if (dueInDays != null) 'dueInDays': dueInDays},
          options: _options(),
        );
  }
}

/// The server's message, or [fallback] (for example when offline).
String questionnaireErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    if (error.response?.statusCode == 404 && error.response?.data is! Map) {
      return 'This needs the latest server update, which isn\'t live yet.';
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

/// True when the doctor needs the patient's consent to see these answers.
bool questionnaireNeedsConsent(Object error) =>
    error is DioException && error.response?.statusCode == 403;
