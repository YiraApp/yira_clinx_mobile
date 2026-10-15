import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../local/global_session.dart';
import '../local/shared_preferences.dart';
import '../urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/patient_entity.dart';
import 'package:yiraclinics/features/data/models/dashboard/patient_model.dart';

class FavoritePatientEntry {
  final String primaryId;
  final String alternateId;

  FavoritePatientEntry({
    required this.primaryId,
    this.alternateId = '',
  });

  String get canonicalKey {
    final p = primaryId.trim();
    final a = alternateId.trim();
    if (p.isNotEmpty) return p;
    return a;
  }

  bool matches(String id) {
    if (id.isEmpty) return false;
    final clean = id.trim();
    return (primaryId.isNotEmpty && clean == primaryId.trim()) ||
        (alternateId.isNotEmpty && clean == alternateId.trim());
  }

  Map<String, dynamic> toJson() => {
        'primaryId': primaryId,
        'alternateId': alternateId,
      };

  factory FavoritePatientEntry.fromJson(Map<String, dynamic> json) => FavoritePatientEntry(
        primaryId: json['primaryId']?.toString().trim() ?? '',
        alternateId: json['alternateId']?.toString().trim() ?? '',
      );
}

class FavoritePatientsService {
  static final FavoritePatientsService _instance = FavoritePatientsService._internal();
  factory FavoritePatientsService() => _instance;
  FavoritePatientsService._internal();

  /// Holds the set of canonical patient keys (exactly 1 per unique favorite patient)
  final ValueNotifier<Set<String>> favoriteIdsNotifier = ValueNotifier<Set<String>>({});

  /// In-memory list of unique favorite patient entries
  List<FavoritePatientEntry> _entries = [];

  /// Fast lookup set containing both primary and alternate IDs of all favorited patients
  final Set<String> _lookupIds = <String>{};

  /// Returns the count of unique favorite patients
  int get favoriteCount => _entries.length;

  String _resolveDoctorId([String? doctorId]) {
    if (doctorId != null && doctorId.trim().isNotEmpty) return doctorId.trim();
    final user = GlobalSession.instance.userNotifier.value?.data;
    if (user?.id != null && user!.id!.trim().isNotEmpty) return user.id!.trim();
    if (user?.navigationId != null && user!.navigationId!.trim().isNotEmpty) return user.navigationId!.trim();
    return '1';
  }

  String _getStorageKey([String? doctorId]) {
    final String docId = _resolveDoctorId(doctorId);
    return 'doctor_fav_patients_$docId';
  }

  void _rebuildLookupAndNotify() {
    _lookupIds.clear();
    final Set<String> canonicalSet = <String>{};
    for (final entry in _entries) {
      if (entry.primaryId.trim().isNotEmpty) {
        _lookupIds.add(entry.primaryId.trim());
      }
      if (entry.alternateId.trim().isNotEmpty) {
        _lookupIds.add(entry.alternateId.trim());
      }
      final cKey = entry.canonicalKey;
      if (cKey.isNotEmpty) {
        canonicalSet.add(cKey);
      }
    }
    favoriteIdsNotifier.value = canonicalSet;
  }

  bool _hasOldFormatStrings(List<String> list) {
    return list.any((s) => !s.trim().startsWith('{'));
  }

  List<FavoritePatientEntry> _parseStoredFavorites(List<String> rawList) {
    final List<FavoritePatientEntry> parsed = [];
    final List<String> oldPlainStrings = [];

    for (final item in rawList) {
      final str = item.trim();
      if (str.isEmpty) continue;
      if (str.startsWith('{') && str.endsWith('}')) {
        try {
          final decoded = jsonDecode(str);
          if (decoded is Map<String, dynamic>) {
            parsed.add(FavoritePatientEntry.fromJson(decoded));
            continue;
          }
        } catch (_) {}
      }
      oldPlainStrings.add(str);
    }

    if (oldPlainStrings.isNotEmpty) {
      // Migrate old format where both userId and id were stored as plain strings
      bool isUuid(String s) => s.contains('-') || s.length > 20;
      final uuids = oldPlainStrings.where(isUuid).toList();
      final nonUuids = oldPlainStrings.where((s) => !isUuid(s)).toList();

      if (uuids.isNotEmpty && nonUuids.isNotEmpty) {
        final count = uuids.length >= nonUuids.length ? uuids.length : nonUuids.length;
        for (int i = 0; i < count; i++) {
          final u = i < uuids.length ? uuids[i] : '';
          final nu = i < nonUuids.length ? nonUuids[i] : '';
          final pKey = u.isNotEmpty ? u : nu;
          final aKey = (nu.isNotEmpty && nu != pKey) ? nu : '';
          if (pKey.isNotEmpty) {
            parsed.add(FavoritePatientEntry(primaryId: pKey, alternateId: aKey));
          }
        }
      } else {
        // Only one type existed, each is one entry
        for (final s in oldPlainStrings) {
          parsed.add(FavoritePatientEntry(primaryId: s));
        }
      }
    }

    // Deduplicate parsed list by canonicalKey
    final seen = <String>{};
    final List<FavoritePatientEntry> unique = [];
    for (final e in parsed) {
      final k = e.canonicalKey;
      if (k.isNotEmpty && !seen.contains(k)) {
        seen.add(k);
        unique.add(e);
      }
    }
    return unique;
  }

  Future<void> _saveToStorage([String? doctorId]) async {
    final prefs = sl<SharedPrefsService>();
    final key = _getStorageKey(doctorId);
    final rawList = _entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setValue(key, rawList);
  }

  /// Initialize and load favorites from local storage & sync with backend
  Future<Set<String>> loadFavorites([String? doctorId]) async {
    final prefs = sl<SharedPrefsService>();
    final key = _getStorageKey(doctorId);
    final rawList = prefs.getStringList(key);

    _entries = _parseStoredFavorites(rawList);
    _rebuildLookupAndNotify();

    // If we migrated from old format, re-save in new clean format immediately
    if (rawList.isNotEmpty && _hasOldFormatStrings(rawList)) {
      await _saveToStorage(doctorId);
    }

    // Background sync with backend (await if local cache is empty so initial load populates)
    if (_entries.isEmpty) {
      await _syncWithBackend(doctorId);
      return favoriteIdsNotifier.value;
    } else {
      _syncWithBackend(doctorId);
      return favoriteIdsNotifier.value;
    }
  }

  Future<void> _syncWithBackend(String? doctorId) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String docId = _resolveDoctorId(doctorId);
      final int orgId = currentUser?.data?.latestOrgId ?? 1;
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.favoritePatientsListUrl,
        data: {
          "doctorId": docId,
          "orgId": orgId,
          "hospitalId": hospitalId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final data = rawData['data'];
        List<dynamic> favList = [];
        if (data is Map && data['patients'] is List) {
          favList = data['patients'] as List;
        } else if (data is List) {
          favList = data;
        }

        if (favList.isNotEmpty) {
          final List<FavoritePatientEntry> synced = [];
          for (final item in favList) {
            final uid = item['userId']?.toString().trim() ?? '';
            final id = item['id']?.toString().trim() ?? '';
            final pKey = uid.isNotEmpty ? uid : id;
            final aKey = (id.isNotEmpty && id != pKey) ? id : '';
            if (pKey.isNotEmpty) {
              synced.add(FavoritePatientEntry(primaryId: pKey, alternateId: aKey));
            }
          }

          final seen = <String>{};
          final List<FavoritePatientEntry> uniqueSynced = [];
          for (final e in synced) {
            final k = e.canonicalKey;
            if (k.isNotEmpty && !seen.contains(k)) {
              seen.add(k);
              uniqueSynced.add(e);
            }
          }

          _entries = uniqueSynced;
          _rebuildLookupAndNotify();
          await _saveToStorage(doctorId);
        }
      }
    } catch (_) {
      // Offline fallback: keep local cache
    }
  }

  /// Check if a patient is currently marked as favorite
  bool isFavorite(String patientId, [String? alternateId]) {
    final pId = patientId.trim();
    final aId = alternateId?.trim() ?? '';
    if (pId.isEmpty && aId.isEmpty) return false;

    if (pId.isNotEmpty && _lookupIds.contains(pId)) return true;
    if (aId.isNotEmpty && _lookupIds.contains(aId)) return true;

    for (final e in _entries) {
      if ((pId.isNotEmpty && e.matches(pId)) ||
          (aId.isNotEmpty && e.matches(aId))) {
        return true;
      }
    }
    return false;
  }

  /// Links primary and alternate IDs of a known patient into the favorite registry
  void registerPatientPair(String primaryId, String alternateId) {
    final pId = primaryId.trim();
    final aId = alternateId.trim();
    if (pId.isEmpty && aId.isEmpty) return;

    for (int i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.matches(pId) || e.matches(aId)) {
        final newP = e.primaryId.isNotEmpty ? e.primaryId : pId;
        final newA = e.alternateId.isNotEmpty ? e.alternateId : aId;
        _entries[i] = FavoritePatientEntry(primaryId: newP, alternateId: newA);
        if (newP.isNotEmpty) _lookupIds.add(newP);
        if (newA.isNotEmpty) _lookupIds.add(newA);
        break;
      }
    }
  }

  /// Toggle favorite status of a patient, persist locally, and sync to backend
  Future<bool> toggleFavorite({
    required String patientId,
    String? alternateId,
    String? doctorId,
  }) async {
    final String pId = patientId.trim();
    final String aId = alternateId?.trim() ?? '';
    if (pId.isEmpty && aId.isEmpty) return false;

    final String primaryKey = pId.isNotEmpty ? pId : aId;
    final String aliasKey = (aId.isNotEmpty && aId != primaryKey) ? aId : '';

    final bool isCurrentlyFav = isFavorite(pId, aId);
    bool isNowFav;

    if (isCurrentlyFav) {
      _entries.removeWhere((e) =>
          (pId.isNotEmpty && e.matches(pId)) ||
          (aId.isNotEmpty && e.matches(aId)));
      isNowFav = false;
    } else {
      _entries.removeWhere((e) =>
          (pId.isNotEmpty && e.matches(pId)) ||
          (aId.isNotEmpty && e.matches(aId)));
      _entries.add(FavoritePatientEntry(primaryId: primaryKey, alternateId: aliasKey));
      isNowFav = true;
    }

    _rebuildLookupAndNotify();
    await _saveToStorage(doctorId);

    // Sync to backend asynchronously
    _sendToggleToBackend(primaryKey, isNowFav, doctorId);

    return isNowFav;
  }

  Future<void> _sendToggleToBackend(String patientId, bool isFav, String? doctorId) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String docId = doctorId ?? (currentUser?.data?.id ?? '1');
      final String token = currentUser?.data?.accessToken ?? '';

      await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.toggleFavoritePatientUrl,
        data: {
          "doctorId": docId,
          "patientId": patientId,
          "isFavorite": isFav,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
    } catch (_) {
      // Local state is already saved
    }
  }

  /// Fetch all favorite patients entities for the doctor
  Future<List<PatientEntity>> fetchFavoritePatients([String? doctorId]) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final String docId = _resolveDoctorId(doctorId);
    final int orgId = currentUser?.data?.latestOrgId ?? 1;
    final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
    final String token = currentUser?.data?.accessToken ?? '';

    await loadFavorites(docId);

    try {
      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.patientsListUrl,
        data: {
          "doctorId": docId,
          "orgId": orgId,
          "hospitalId": hospitalId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      List<PatientEntity> all = [];
      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final rawList = rawData['data'];
        List<dynamic> list = [];
        if (rawList is List) {
          list = rawList;
        } else if (rawList is Map<String, dynamic> && rawList['patients'] is List) {
          list = rawList['patients'] as List;
        }

        all = list.map((item) {
          final model = PatientModel.fromJson(item as Map<String, dynamic>);
          final fav = isFavorite(model.userId, model.id);
          return model.copyWith(isFavorite: fav);
        }).toList();
      }

      // Deduplicate by patient userId or id
      final seenIds = <String>{};
      final List<PatientEntity> uniqueFavs = [];
      for (final p in all) {
        final bool fav = isFavorite(p.userId, p.id) || p.isFavorite;
        if (fav) {
          final uniqueKey = p.userId.isNotEmpty ? p.userId : p.id;
          if (uniqueKey.isNotEmpty && !seenIds.contains(uniqueKey)) {
            seenIds.add(uniqueKey);
            uniqueFavs.add(p);
          }
        }
      }

      return uniqueFavs;
    } catch (e) {
      return [];
    }
  }
}
