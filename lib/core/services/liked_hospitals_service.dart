import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

/// Service responsible for managing and fetching liked, linked, and authorized
/// hospitals and associated doctors exclusively for patient users.
class LikedHospitalsService {
  static final LikedHospitalsService _instance = LikedHospitalsService._internal();
  factory LikedHospitalsService() => _instance;
  static LikedHospitalsService get instance => _instance;
  LikedHospitalsService._internal();

  /// ValueNotifier to allow UI components to reactively listen to liked/linked hospital changes
  final ValueNotifier<List<Map<String, dynamic>>> linkedHospitalsNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  /// Retrieves all hospitals that are explicitly liked, linked, or registered to this patient.
  /// Deduplicates across:
  /// 1. Patient's Linked Doctors (`patient_linked_doctors_$patientId`)
  /// 2. Patient's Explicit Liked Hospitals (`patient_liked_hospitals_$patientId`)
  /// 3. Patient's Registered Workspaces from the backend API
  Future<List<Map<String, dynamic>>> getLikedAndLinkedHospitals({
    String? patientId,
    Map<String, dynamic>? initialDoctor,
    dynamic initialHospitalId,
  }) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final resolvedPatientId = (patientId ?? currentUser?.data?.id ?? '').toString().trim();
    final token = currentUser?.data?.accessToken ?? '';
    final roleId = (currentUser?.data?.latestRoleId ?? '4FC67429-28AE-4106-93EF-436228282ED0').trim();

    final List<Map<String, dynamic>> hospitals = [];
    final Set<String> seenHospitalKeys = {};

    void addHospital(
      dynamic id,
      dynamic name, {
      dynamic orgId,
      dynamic orgName,
      dynamic hospitalCode,
      dynamic hospitalType,
      dynamic address,
      dynamic city,
      dynamic state,
      dynamic country,
      dynamic pincode,
      dynamic helplineNumber,
      dynamic mobileNumber,
      dynamic email,
      dynamic website,
      dynamic openingTime,
      dynamic closingTime,
      dynamic is24Hours,
      dynamic totalBeds,
      dynamic emergencyBeds,
      dynamic icuBeds,
      dynamic ambulances,
      bool isLiked = false,
    }) {
      if (id == null) return;
      final hospIdStr = id.toString().trim();
      final hospNameStr = (name ?? '').toString().trim();
      if (hospIdStr.isEmpty || hospNameStr.isEmpty) return;

      // Filter out generic placeholder names
      if (hospNameStr.toLowerCase() == 'user' || hospNameStr.toLowerCase() == 'null') return;

      final key = '$hospIdStr|${hospNameStr.toLowerCase()}';
      if (!seenHospitalKeys.contains(key)) {
        seenHospitalKeys.add(key);
        hospitals.add({
          'id': int.tryParse(hospIdStr) ?? hospIdStr,
          'name': hospNameStr,
          'hospitalCode': (hospitalCode ?? 'HOSP-$hospIdStr').toString(),
          'orgId': orgId != null ? (int.tryParse(orgId.toString()) ?? 1) : 1,
          'orgName': (orgName ?? 'Healthcare Facility').toString(),
          'hospitalType': hospitalType?.toString(),
          'address': address?.toString(),
          'city': city?.toString(),
          'state': state?.toString(),
          'country': country?.toString(),
          'pincode': pincode?.toString(),
          'helplineNumber': helplineNumber?.toString(),
          'mobileNumber': mobileNumber?.toString(),
          'email': email?.toString(),
          'website': website?.toString(),
          'openingTime': openingTime?.toString(),
          'closingTime': closingTime?.toString(),
          'is24Hours': is24Hours == true || is24Hours == 1 || is24Hours == '1' || is24Hours == 'true',
          'totalBeds': totalBeds != null ? int.tryParse(totalBeds.toString()) : null,
          'emergencyBeds': emergencyBeds != null ? int.tryParse(emergencyBeds.toString()) : null,
          'icuBeds': icuBeds != null ? int.tryParse(icuBeds.toString()) : null,
          'ambulances': ambulances != null ? int.tryParse(ambulances.toString()) : null,
          'isLiked': isLiked,
          'isLinked': true,
        });
      }
    }

    // 0. Ensure Default Organization & Hospital (Yira Hospitals) is always added for every patient with actual ID 19
    addHospital(
      19,
      'Yira Hospitals',
      orgId: 1,
      orgName: 'yira',
      city: 'Hyderabad',
      address: 'Jubilee Hills, Road No 36, Hyderabad',
      hospitalType: 'Super-Specialty Hospital',
      helplineNumber: '+91 8008123456',
      is24Hours: true,
      isLiked: true,
    );

    // If patient has another latestHospitalId from session, add that as well
    final sessionHospId = currentUser?.data?.latestHospitalId;
    if (sessionHospId != null && sessionHospId != 19) {
      final sessionOrgId = currentUser?.data?.latestOrgId ?? 1;
      addHospital(
        sessionHospId,
        'Hospital ($sessionHospId)',
        orgId: sessionOrgId,
        orgName: 'Healthcare Facility',
        isLiked: true,
      );
    }

    // 1. Load from initial arguments if provided
    if (initialDoctor != null) {
      final docHospId = initialDoctor['hospitalId'];
      final docHospName = initialDoctor['hospitalName'];
      if (docHospId != null && docHospName != null) {
        addHospital(
          docHospId,
          docHospName,
          orgId: initialDoctor['orgId'],
          orgName: initialDoctor['orgName'],
          hospitalCode: initialDoctor['hospitalCode'],
          city: initialDoctor['city'],
          address: initialDoctor['address'],
        );
      }
    }

    if (resolvedPatientId.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();

        // 2. Load hospitals from Patient's Linked Doctors
        final linkedDocsKey = 'patient_linked_doctors_$resolvedPatientId';
        final localDocsStr = prefs.getString(linkedDocsKey);
        if (localDocsStr != null && localDocsStr.isNotEmpty) {
          final List<dynamic> localDocs = jsonDecode(localDocsStr);
          for (final doc in localDocs) {
            if (doc is Map<String, dynamic>) {
              final hId = doc['hospitalId'];
              final hName = doc['hospitalName'];
              if (hId != null && hName != null) {
                addHospital(
                  hId,
                  hName,
                  orgId: doc['orgId'],
                  orgName: doc['orgName'],
                  hospitalCode: doc['hospitalCode'],
                  city: doc['city'],
                  address: doc['address'],
                );
              }
            }
          }
        }

        // 3. Load hospitals from Patient's Saved/Liked Hospitals list
        final likedHospKey = 'patient_liked_hospitals_$resolvedPatientId';
        final likedHospStr = prefs.getString(likedHospKey);
        if (likedHospStr != null && likedHospStr.isNotEmpty) {
          final List<dynamic> likedList = jsonDecode(likedHospStr);
          for (final h in likedList) {
            if (h is Map<String, dynamic>) {
              final hId = h['id'] ?? h['hospitalId'];
              final hName = h['name'] ?? h['hospitalName'];
              if (hId != null && hName != null) {
                addHospital(
                  hId,
                  hName,
                  orgId: h['orgId'],
                  orgName: h['orgName'],
                  hospitalCode: h['hospitalCode'] ?? h['code'],
                  hospitalType: h['hospitalType'],
                  city: h['city'],
                  address: h['address'],
                  isLiked: true,
                );
              }
            }
          }
        }

        // 4. Fetch registered workspaces from backend API (Linked Hospitals)
        final res = await sl<ApiClient>().account(showSuccessSnack: false).get(
          URLs.workspaceDetailsUrl,
          queryParameters: {
            'userId': resolvedPatientId,
            'roleId': roleId,
          },
          options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
        );

        if (res.data != null && res.data['data'] != null) {
          final rawData = res.data['data'];
          if (rawData is List) {
            for (final org in rawData) {
              if (org is Map<String, dynamic>) {
                final orgId = org['organizationId'] ?? org['OrganizationId'];
                final orgName = org['organizationName'] ?? org['OrganizationName'];
                final hospList = org['hospitals'] ?? org['Hospitals'];
                if (hospList is List) {
                  for (final h in hospList) {
                    if (h is Map<String, dynamic>) {
                      addHospital(
                        h['hospitalId'] ?? h['HospitalId'] ?? h['id'] ?? h['Id'],
                        h['hospitalName'] ?? h['HospitalName'] ?? h['name'] ?? h['Name'],
                        orgId: orgId,
                        orgName: orgName,
                        hospitalCode: h['hospitalCode'] ?? h['HospitalCode'] ?? h['code'],
                        city: h['city'] ?? h['City'],
                        address: h['address'] ?? h['Address'],
                      );
                    }
                  }
                }
              }
            }
          } else if (rawData is Map<String, dynamic>) {
            final wsList = rawData['workspaces'] ?? rawData['hospitals'] ?? rawData['data'];
            if (wsList is List) {
              for (final ws in wsList) {
                if (ws is Map<String, dynamic>) {
                  final hospId = ws['hospitalId'] ?? ws['HospitalId'] ?? ws['id'] ?? ws['Id'];
                  final hospName = ws['hospitalName'] ?? ws['HospitalName'] ?? ws['name'] ?? ws['Name'];
                  final orgId = ws['organizationId'] ?? ws['OrganizationId'];
                  final orgName = ws['organizationName'] ?? ws['OrganizationName'];
                  if (hospId != null && hospName != null) {
                    addHospital(
                      hospId,
                      hospName,
                      orgId: orgId,
                      orgName: orgName,
                      hospitalCode: ws['hospitalCode'] ?? ws['HospitalCode'] ?? ws['code'],
                      city: ws['city'] ?? ws['City'],
                      address: ws['address'] ?? ws['Address'],
                    );
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[LikedHospitalsService] Error loading liked/linked hospitals: $e');
      }
    }

    linkedHospitalsNotifier.value = hospitals;
    return hospitals;
  }

  /// Retrieves all doctors linked to this patient that belong to the given hospital.
  Future<List<Map<String, dynamic>>> getLinkedDoctorsForHospital({
    required dynamic hospitalId,
    String? patientId,
    Map<String, dynamic>? initialDoctor,
  }) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final resolvedPatientId = (patientId ?? currentUser?.data?.id ?? '').toString().trim();
    final hospIdStr = hospitalId.toString().trim();

    final List<Map<String, dynamic>> matchedDoctors = [];
    final Set<String> seenDocIds = {};

    void addDoctor(Map<String, dynamic> doc) {
      final docId = (doc['doctorId'] ?? doc['id'] ?? '').toString().trim();
      final docName = (doc['name'] ?? '').toString().trim();
      if (docId.isEmpty && docName.isEmpty) return;

      final lowerName = docName.toLowerCase();
      // Exclude test / dummy data
      if (lowerName.contains('test') ||
          lowerName.contains('dummy') ||
          lowerName.contains('sample') ||
          lowerName.contains('demo') ||
          lowerName.contains('fake') ||
          lowerName.contains('sarah jenkins') ||
          lowerName.contains('robert miller')) {
        return;
      }

      final key = docId.isNotEmpty ? docId : lowerName;
      if (!seenDocIds.contains(key)) {
        seenDocIds.add(key);
        matchedDoctors.add(doc);
      }
    }

    // 1. If initial doctor matches this hospital, add it first
    if (initialDoctor != null) {
      final initHospId = (initialDoctor['hospitalId'] ?? '').toString().trim();
      if (initHospId.isEmpty || initHospId == hospIdStr) {
        addDoctor(initialDoctor);
      }
    }

    // 2. Fetch all doctors belonging to this hospital from backend API
    final token = currentUser?.data?.accessToken ?? '';
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).get(
        URLs.hospitalDoctorsUrl,
        queryParameters: {'hospitalId': hospIdStr},
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );

      if (res.data != null) {
        final rawData = res.data['data'];
        List<dynamic> list = [];
        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map && rawData['data'] is List) {
          list = rawData['data'] as List;
        }
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            addDoctor(item);
          }
        }
      }
    } catch (e) {
      debugPrint('[LikedHospitalsService] Error fetching doctors from backend for hospital $hospIdStr: $e');
    }

    // 3. Load from patient_linked_doctors_$patientId
    if (resolvedPatientId.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final linkedDocsKey = 'patient_linked_doctors_$resolvedPatientId';
        final localDocsStr = prefs.getString(linkedDocsKey);
        if (localDocsStr != null && localDocsStr.isNotEmpty) {
          final List<dynamic> localDocs = jsonDecode(localDocsStr);
          for (final item in localDocs) {
            if (item is Map<String, dynamic>) {
              final docHospId = (item['hospitalId'] ?? '').toString().trim();
              if (docHospId.isEmpty || docHospId == hospIdStr) {
                addDoctor(item);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[LikedHospitalsService] Error loading linked doctors: $e');
      }
    }

    return matchedDoctors;
  }

  /// Saves a hospital to the patient's liked hospitals list.
  Future<void> saveLikedHospital(Map<String, dynamic> hospital, {String? patientId}) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final resolvedPatientId = (patientId ?? currentUser?.data?.id ?? '').toString().trim();
    if (resolvedPatientId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final likedHospKey = 'patient_liked_hospitals_$resolvedPatientId';
      final existingStr = prefs.getString(likedHospKey);
      List<Map<String, dynamic>> list = [];
      if (existingStr != null) {
        final List<dynamic> raw = jsonDecode(existingStr);
        list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      final hospId = hospital['id'] ?? hospital['hospitalId'];
      list.removeWhere((h) => (h['id'] ?? h['hospitalId'])?.toString() == hospId?.toString());
      list.insert(0, {
        'id': hospId,
        'name': hospital['name'] ?? hospital['hospitalName'],
        'orgId': hospital['orgId'] ?? 1,
        'orgName': hospital['orgName'] ?? 'Healthcare Facility',
        'isLiked': true,
        'isLinked': true,
      });

      await prefs.setString(likedHospKey, jsonEncode(list));
      await getLikedAndLinkedHospitals(patientId: resolvedPatientId);
    } catch (e) {
      debugPrint('[LikedHospitalsService] Error saving liked hospital: $e');
    }
  }

  /// Removes a hospital from the patient's liked hospitals list.
  Future<void> removeLikedHospital(dynamic hospitalId, {String? patientId}) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final resolvedPatientId = (patientId ?? currentUser?.data?.id ?? '').toString().trim();
    if (resolvedPatientId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final likedHospKey = 'patient_liked_hospitals_$resolvedPatientId';
      final existingStr = prefs.getString(likedHospKey);
      if (existingStr != null) {
        final List<dynamic> raw = jsonDecode(existingStr);
        final list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
        list.removeWhere((h) => (h['id'] ?? h['hospitalId'])?.toString() == hospitalId?.toString());
        await prefs.setString(likedHospKey, jsonEncode(list));
      }
      await getLikedAndLinkedHospitals(patientId: resolvedPatientId);
    } catch (e) {
      debugPrint('[LikedHospitalsService] Error removing liked hospital: $e');
    }
  }

  /// Automatically saves and establishes a permanent connection with a doctor.
  Future<void> saveLinkedDoctor(Map<String, dynamic> doctor, {String? patientId}) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final resolvedPatientId = (patientId ?? currentUser?.data?.id ?? '').toString().trim();
    if (resolvedPatientId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final linkedDocsKey = 'patient_linked_doctors_$resolvedPatientId';
      final existingStr = prefs.getString(linkedDocsKey);
      List<Map<String, dynamic>> list = [];
      if (existingStr != null) {
        final List<dynamic> raw = jsonDecode(existingStr);
        list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      final docId = doctor['doctorId'] ?? doctor['id'];
      list.removeWhere((d) => (d['doctorId'] ?? d['id'])?.toString() == docId?.toString());
      list.insert(0, {
        ...doctor,
        'isLinked': true,
      });

      await prefs.setString(linkedDocsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[LikedHospitalsService] Error saving linked doctor: $e');
    }
  }
}
