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

class FavoritePatientsService {
  static final FavoritePatientsService _instance = FavoritePatientsService._internal();
  factory FavoritePatientsService() => _instance;
  FavoritePatientsService._internal();

  final ValueNotifier<Set<String>> favoriteIdsNotifier = ValueNotifier<Set<String>>({});

  String _getStorageKey([String? doctorId]) {
    final String docId = (doctorId != null && doctorId.trim().isNotEmpty)
        ? doctorId.trim()
        : (GlobalSession.instance.userNotifier.value?.data?.id ?? 'default_doc');
    return 'doctor_fav_patients_$docId';
  }

  /// Initialize and load favorites from local storage & sync with backend
  Future<Set<String>> loadFavorites([String? doctorId]) async {
    final prefs = sl<SharedPrefsService>();
    final key = _getStorageKey(doctorId);
    final list = prefs.getStringList(key);
    final set = list.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    favoriteIdsNotifier.value = set;

    // Background sync with backend
    _syncWithBackend(doctorId);

    return set;
  }

  Future<void> _syncWithBackend(String? doctorId) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String docId = doctorId ?? (currentUser?.data?.id ?? '1');
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

        // Add exactly 1 unique canonical ID per patient
        final Set<String> updatedSet = <String>{};
        for (final item in favList) {
          final uid = item['userId']?.toString().trim() ?? '';
          final id = item['id']?.toString().trim() ?? '';
          final canonicalId = uid.isNotEmpty ? uid : id;
          if (canonicalId.isNotEmpty) {
            updatedSet.add(canonicalId);
          }
        }

        favoriteIdsNotifier.value = updatedSet;
        final prefs = sl<SharedPrefsService>();
        final key = _getStorageKey(doctorId);
        await prefs.setValue(key, updatedSet.toList());
      }
    } catch (_) {
      // Offline fallback: keep local cache
    }
  }

  /// Check if a patient is currently marked as favorite
  bool isFavorite(String patientId, [String? alternateId]) {
    final set = favoriteIdsNotifier.value;
    final pId = patientId.trim();
    final aId = alternateId?.trim();
    return (pId.isNotEmpty && set.contains(pId)) || (aId != null && aId.isNotEmpty && set.contains(aId));
  }

  /// Toggle favorite status of a patient, persist locally, and sync to backend
  Future<bool> toggleFavorite({
    required String patientId,
    String? alternateId,
    String? doctorId,
  }) async {
    final String pId = patientId.trim();
    final String aId = alternateId?.trim() ?? '';
    final String primaryKey = pId.isNotEmpty ? pId : aId;
    if (primaryKey.isEmpty) return false;

    final prefs = sl<SharedPrefsService>();
    final key = _getStorageKey(doctorId);
    final current = Set<String>.from(favoriteIdsNotifier.value);

    // Check if either ID is in the set
    final bool isCurrentlyFav = current.contains(pId) || (aId.isNotEmpty && current.contains(aId));
    bool isNowFav;

    if (isCurrentlyFav) {
      if (pId.isNotEmpty) {
        current.remove(pId);
        await prefs.removeIdFromList(key, pId);
      }
      if (aId.isNotEmpty) {
        current.remove(aId);
        await prefs.removeIdFromList(key, aId);
      }
      isNowFav = false;
    } else {
      // Clean up any legacy duplicate before adding the single primary key
      if (aId.isNotEmpty && aId != primaryKey) {
        current.remove(aId);
        await prefs.removeIdFromList(key, aId);
      }
      current.add(primaryKey);
      await prefs.addIdToList(key, primaryKey);
      isNowFav = true;
    }

    favoriteIdsNotifier.value = current;
    await prefs.setValue(key, current.toList());

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
    final String docId = doctorId ?? (currentUser?.data?.id ?? '1');
    final int orgId = currentUser?.data?.latestOrgId ?? 1;
    final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
    final String token = currentUser?.data?.accessToken ?? '';

    final favIds = await loadFavorites(docId);

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
          final isFav = favIds.contains(model.userId.trim()) || favIds.contains(model.id.trim());
          return model.copyWith(isFavorite: isFav);
        }).toList();
      }

      // Deduplicate by patient userId or id
      final seenIds = <String>{};
      final List<PatientEntity> uniqueFavs = [];
      for (final p in all) {
        final isFav = favIds.contains(p.userId.trim()) || favIds.contains(p.id.trim()) || p.isFavorite;
        if (isFav) {
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
