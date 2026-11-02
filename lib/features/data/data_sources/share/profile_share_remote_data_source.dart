import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

/// A read-only web link to the patient's profile.
class ProfileShareLink {
  final int id;
  final String? label;
  final String status; // ACTIVE, EXPIRED, REVOKED
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final int viewCount;
  final DateTime? lastViewedAt;

  /// Only present right after the link is made; the server cannot show it again.
  final String? url;

  const ProfileShareLink({
    required this.id,
    required this.status,
    this.label,
    this.createdAt,
    this.expiresAt,
    this.viewCount = 0,
    this.lastViewedAt,
    this.url,
  });

  bool get isActive => status == 'ACTIVE';

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory ProfileShareLink.fromJson(Map<String, dynamic> json) => ProfileShareLink(
        id: int.tryParse('${json['id']}') ?? 0,
        label: (json['label'] as String?)?.trim().isEmpty == true ? null : json['label'] as String?,
        status: (json['status'] ?? 'ACTIVE').toString().toUpperCase(),
        createdAt: _date(json['createdAt']),
        expiresAt: _date(json['expiresAt']),
        viewCount: int.tryParse('${json['viewCount'] ?? 0}') ?? 0,
        lastViewedAt: _date(json['lastViewedAt']),
        url: json['url'] as String?,
      );
}

/// A doctor on Yira the patient has seen or connected with.
class ShareableDoctor {
  final String id;
  final String name;
  final String specialty;
  final String hospitalName;
  final int? hospitalId;
  final String? photoUrl;

  /// When this doctor can currently read the full history.
  final bool hasAccess;
  final DateTime? accessUntil;

  /// The access record to turn off, when [hasAccess].
  final int? consentId;

  const ShareableDoctor({
    required this.id,
    required this.name,
    this.specialty = '',
    this.hospitalName = '',
    this.hospitalId,
    this.photoUrl,
    this.hasAccess = false,
    this.accessUntil,
    this.consentId,
  });
}

/// Turns a server error into one sentence for the patient.
String shareErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).trim().isNotEmpty) {
      return data['message'] as String;
    }
    if (error.response?.statusCode == 404) return 'This needs the latest Yira server. Please try again later.';
    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
      return 'No internet connection. Check your connection and try again.';
    }
  }
  return fallback;
}

class ProfileShareRemoteDataSource {
  Options get _auth {
    final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
    return Options(headers: {if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token'});
  }

  Dio get _dio => sl<ApiClient>().account(showSuccessSnack: false);

  String get _patientId => (GlobalSession.instance.userNotifier.value?.data?.id ?? '').trim();

  Future<List<ProfileShareLink>> getLinks() async {
    final res = await _dio.get(URLs.profileShareLinksUrl, queryParameters: {'patientId': _patientId}, options: _auth);
    final data = res.data is Map ? res.data['data'] : null;
    return data is List
        ? data.whereType<Map>().map((m) => ProfileShareLink.fromJson(Map<String, dynamic>.from(m))).toList()
        : const [];
  }

  /// [duration] is 1_DAY, 7_DAYS or 30_DAYS.
  Future<ProfileShareLink> createLink({required String duration, String? label}) async {
    final res = await _dio.post(
      URLs.profileShareLinksUrl,
      data: {'patientId': _patientId, 'duration': duration, if ((label ?? '').trim().isNotEmpty) 'label': label!.trim()},
      options: _auth,
    );
    return ProfileShareLink.fromJson(Map<String, dynamic>.from(res.data['data'] as Map));
  }

  Future<void> revokeLink(int id) async {
    await _dio.post('${URLs.profileShareLinksUrl}/$id/revoke', options: _auth);
  }

  /// [duration] uses the consent durations: 1_DAY, 7_DAYS, 1_MONTH.
  Future<void> grantDoctorAccess({required String doctorId, required String duration, int? hospitalId}) async {
    await _dio.post(
      URLs.patientAccessGrantUrl,
      data: {'patientId': _patientId, 'doctorId': doctorId, 'duration': duration, 'hospitalId': ?hospitalId},
      options: _auth,
    );
  }

  Future<void> stopDoctorAccess(int consentId) async {
    await _dio.post(
      URLs.patientConsentRespondUrl,
      data: {'consentId': consentId, 'action': 'REVOKE', 'patientId': _patientId},
      options: _auth,
    );
  }

  /// Doctors from the patient's visits, QR connections and access requests.
  Future<List<ShareableDoctor>> getDoctors() async {
    final patientId = _patientId;
    final byId = <String, ShareableDoctor>{};
    final access = <String, DateTime?>{};
    final consentIds = <String, int>{};

    void add(String id, String name, {String specialty = '', String hospital = '', int? hospitalId, String? photo}) {
      final key = id.trim().toLowerCase();
      // A patient who is also a doctor on Yira should not see themself here.
      if (key.isEmpty || name.trim().isEmpty || key == patientId.toLowerCase()) return;
      final existing = byId[key];
      byId[key] = ShareableDoctor(
        id: id.trim(),
        name: existing?.name ?? name.trim(),
        specialty: (existing?.specialty.isNotEmpty ?? false) ? existing!.specialty : specialty,
        hospitalName: (existing?.hospitalName.isNotEmpty ?? false) ? existing!.hospitalName : hospital,
        hospitalId: existing?.hospitalId ?? hospitalId,
        photoUrl: existing?.photoUrl ?? ((photo ?? '').startsWith('http') ? photo : null),
      );
    }

    try {
      final res = await _dio.get(URLs.patientConsentsListUrl, queryParameters: {'patientId': patientId}, options: _auth);
      final list = res.data is Map ? res.data['data'] : null;
      if (list is List) {
        for (final c in list.whereType<Map>()) {
          final id = (c['doctorId'] ?? '').toString();
          add(id, (c['doctorName'] ?? '').toString(),
              specialty: (c['specialty'] ?? '').toString(),
              hospital: (c['hospitalName'] ?? '').toString(),
              hospitalId: int.tryParse('${c['hospitalId']}'),
              photo: c['doctorPhoto']?.toString());
          final expires = c['expiresAt'] == null ? null : DateTime.tryParse(c['expiresAt'].toString())?.toLocal();
          final active = (c['status'] ?? '').toString().toUpperCase() == 'APPROVED' &&
              (expires == null || expires.isAfter(DateTime.now()));
          if (active) {
            access[id.toLowerCase()] = expires;
            final cid = int.tryParse('${c['id']}');
            if (cid != null) consentIds[id.toLowerCase()] = cid;
          }
        }
      }
    } catch (_) {}

    try {
      final res = await _dio.post(URLs.patientAppointmentsUrl, data: {'userId': patientId}, options: _auth);
      final list = res.data is Map ? res.data['data'] : null;
      if (list is List) {
        for (final a in list.whereType<Map>()) {
          final status = (a['status'] ?? '').toString().toLowerCase();
          if (status.contains('cancel') || status.contains('reject')) continue;
          add((a['doctorId'] ?? '').toString(), (a['doctorName'] ?? '').toString(),
              specialty: (a['specialty'] ?? '').toString(),
              hospital: (a['hospitalName'] ?? '').toString(),
              hospitalId: int.tryParse('${a['hospitalId']}'),
              photo: (a['doctorPhoto'] ?? a['imagePath'])?.toString());
        }
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('patient_linked_doctors_$patientId');
      if (raw != null) {
        for (final d in (jsonDecode(raw) as List).whereType<Map>()) {
          add((d['doctorId'] ?? d['id'] ?? '').toString(), (d['name'] ?? '').toString(),
              specialty: (d['specialty'] ?? '').toString(),
              hospital: (d['hospitalName'] ?? '').toString(),
              hospitalId: int.tryParse('${d['hospitalId']}'),
              photo: d['imagePath']?.toString());
        }
      }
    } catch (_) {}

    final doctors = byId.values
        .map((d) => ShareableDoctor(
              id: d.id,
              name: RegExp(r'^dr\.?\s', caseSensitive: false).hasMatch(d.name) ? d.name : 'Dr. ${d.name}',
              specialty: d.specialty,
              hospitalName: d.hospitalName,
              hospitalId: d.hospitalId,
              photoUrl: d.photoUrl,
              hasAccess: access.containsKey(d.id.toLowerCase()),
              accessUntil: access[d.id.toLowerCase()],
              consentId: consentIds[d.id.toLowerCase()],
            ))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return doctors;
  }
}
