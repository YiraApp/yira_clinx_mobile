import 'dart:io';

import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/data/models/prescriptions/lab_test_model.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/lab_test_entity.dart';

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
String? _text(dynamic v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty || s.toLowerCase() == 'null' ? null : s;
}

List<Map<String, dynamic>> _list(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

class PastVisit {
  PastVisit(Map<String, dynamic> j)
      : date = _date(j['date']),
        status = _text(j['status']),
        type = _text(j['type']),
        reason = _text(j['reason']),
        doctor = _text(j['doctor']),
        hospital = _text(j['hospital']);
  final DateTime? date;
  final String? status, type, reason, doctor, hospital;
}

class PastPrescription {
  PastPrescription(Map<String, dynamic> j)
      : date = _date(j['date']),
        doctor = _text(j['doctor']),
        hospital = _text(j['hospital']),
        // Stored text sometimes carries stray separators (",viral pyrexia").
        diagnoses = (j['diagnoses'] is List ? j['diagnoses'] as List : const [])
            .map((e) => '$e'.replaceAll(RegExp(r'^[\s,;]+|[\s,;]+$'), ''))
            .where((e) => e.isNotEmpty)
            .toList(),
        medicines = _list(j['medications']).map((m) => _text(m['name'])).whereType<String>().toList(),
        medicineDetails = _list(j['medications'])
            .where((m) => _text(m['name']) != null)
            .map((m) => (
                  _text(m['name'])!,
                  [_text(m['dosage']), _text(m['frequency']), _text(m['duration']), _text(m['route'])].whereType<String>().join(' • '),
                ))
            .toList(),
        labTests = PrescribedLabTestModel.listFromJson(j['labTests'] ?? j['LabTests']),
        notes = _text(j['notes']),
        pdfUrl = _text(j['pdfUrl']);
  final DateTime? date;
  final String? doctor, hospital, pdfUrl, notes;
  final List<PrescribedLabTest> labTests;
  final List<String> diagnoses, medicines;

  /// Each medicine with its dose, timing and duration, for the history list.
  final List<(String, String)> medicineDetails;
}

class PastRecord {
  PastRecord(Map<String, dynamic> j)
      : date = _date(j['date']),
        type = _text(j['type']),
        complaint = _text(j['chiefComplaint']),
        diagnosis = _text(j['diagnosis']),
        doctor = _text(j['doctor']),
        hospital = _text(j['hospital']);
  final DateTime? date;
  final String? type, complaint, diagnosis, doctor, hospital;
}

class PastDocument {
  PastDocument(Map<String, dynamic> j)
      : name = _text(j['name']) ?? 'Document',
        category = _text(j['category']),
        date = _date(j['date']),
        url = _text(j['url']),
        hospital = _text(j['hospital']);
  final String name;
  final String? category, url, hospital;
  final DateTime? date;
}

class LatestVital {
  const LatestVital(this.key, this.value, this.unit, this.date);
  final String key, value, unit;
  final DateTime? date;
}

/// A patient's history for the doctor's appointment page.
class PastRecords {
  PastRecords.fromJson(Map<String, dynamic> j)
      : allHospitals = j['scope'] == 'all',
        accessExpiresAt = _date(j['accessExpiresAt']),
        visits = _list(j['appointments']).map(PastVisit.new).toList(),
        prescriptions = _list(j['prescriptions']).map(PastPrescription.new).toList(),
        records = _list(j['medicalRecords']).map(PastRecord.new).toList(),
        documents = _list(j['documents']).map(PastDocument.new).toList(),
        activeMedicines = _list(j['medicines'])
            .where((m) => m['active'] == true)
            .map((m) => [_text(m['name']), _text(m['dosage'])].whereType<String>().join(' '))
            .where((s) => s.isNotEmpty)
            .toList(),
        vitals = (j['vitals'] is Map ? Map<String, dynamic>.from(j['vitals']) : <String, dynamic>{})
            .entries
            .where((e) => e.value is Map)
            .map((e) => LatestVital(e.key, '${e.value['value']}', '${e.value['unit'] ?? ''}', _date(e.value['date'])))
            .toList(),
        fitness = _list(j['fitness']);

  /// True with the patient's consent (or as their treating doctor); false
  /// when only this hospital's own records are visible.
  final bool allHospitals;
  final DateTime? accessExpiresAt;
  final List<PastVisit> visits;
  final List<PastPrescription> prescriptions;
  final List<PastRecord> records;
  final List<PastDocument> documents;
  final List<String> activeMedicines;
  final List<LatestVital> vitals;
  final List<Map<String, dynamic>> fitness;

  bool get isEmpty =>
      visits.isEmpty && prescriptions.isEmpty && records.isEmpty && documents.isEmpty && vitals.isEmpty && activeMedicines.isEmpty;

  /// Averages over the most recent week of synced fitness days, or null.
  ({int? steps, int? sleepMinutes, int? restingHr})? get weekFitness {
    if (fitness.isEmpty) return null;
    final week = fitness.take(7).toList();
    int? avg(String key) {
      final v = week.map((d) => d[key]).whereType<num>().where((n) => n > 0).toList();
      return v.isEmpty ? null : (v.reduce((a, b) => a + b) / v.length).round();
    }

    final r = (steps: avg('steps'), sleepMinutes: avg('sleepMinutes'), restingHr: avg('restingHeartRate'));
    return r.steps == null && r.sleepMinutes == null && r.restingHr == null ? null : r;
  }
}

/// The past-records request either returns records or says the doctor needs consent.
class PastRecordsResult {
  const PastRecordsResult.records(PastRecords this.records)
      : needsConsent = false,
        consentStatus = null;
  const PastRecordsResult.locked(this.consentStatus)
      : records = null,
        needsConsent = true;
  final PastRecords? records;
  final bool needsConsent;
  final String? consentStatus;
}

class PastRecordsRemoteDataSource {
  Future<PastRecordsResult> fetch({required String patientId, String? appointmentId, String? hospitalId}) async {
    final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).get(
            '${URLs.providerPatientsUrl}/$patientId/past-records',
            queryParameters: {
              if ((appointmentId ?? '').isNotEmpty) 'appointmentId': appointmentId,
              if ((hospitalId ?? '').isNotEmpty) 'hospitalId': hospitalId,
            },
            options: Options(
              headers: {if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token'},
              extra: {'suppressErrorSnack': true},
            ),
          );
      final data = res.data is Map ? res.data['data'] : null;
      if (data is Map) return PastRecordsResult.records(PastRecords.fromJson(Map<String, dynamic>.from(data)));
      throw Exception('Unexpected response');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final body = e.response?.data;
        final status = body is Map && body['data'] is Map ? body['data']['consentStatus']?.toString() : null;
        return PastRecordsResult.locked(status);
      }
      rethrow;
    }
  }
}
