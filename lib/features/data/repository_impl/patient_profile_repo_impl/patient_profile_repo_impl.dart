import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../../../domain/repositories/patient_profile/patient_profile_repo.dart';

class PatientRepositoryImpl implements PatientRepository {
  final ApiClient _apiClient;

  PatientRepositoryImpl(this._apiClient);

  @override
  Future<PatientProfileEntity> getPatientProfile(String patientId, {String? patientName}) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      final orgId = currentUser?.data?.latestOrgId ?? 1;
      final hospitalId = currentUser?.data?.latestHospitalId ?? 1;

      final response = await _apiClient.account(showSuccessSnack: false).post(
        URLs.patientOverViewUrl,
        data: {
          "patientId": patientId,
          "orgId": orgId,
          "hospitalId": hospitalId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic rawData = response.data is Map<String, dynamic>
            ? response.data['data']
            : (response.data is String ? jsonDecode(response.data)['data'] : null);

        if (rawData != null && rawData is Map) {
          final data = Map<String, dynamic>.from(rawData);
          final contact = Map<String, dynamic>.from(data['contact_information'] ?? {});
          final medical = Map<String, dynamic>.from(data['medical_information'] ?? {});
          final insurance = Map<String, dynamic>.from(data['insurance'] ?? {});
          final visitHistory = Map<String, dynamic>.from(data['visit_history'] ?? {});
          final emergency = Map<String, dynamic>.from(contact['emergency_contact'] ?? {});

          final rawPhone = contact['phone']?.toString().trim() ?? '';
          final phone = (rawPhone == 'None' || rawPhone == 'null') ? '' : rawPhone;

          final rawEmail = contact['email_address']?.toString().trim() ?? contact['email']?.toString().trim() ?? '';
          final email = (rawEmail == 'None' || rawEmail == 'null') ? '' : rawEmail;

          final rawAddress = contact['residential_address']?.toString().trim() ?? '';
          final address = (rawAddress == 'None' || rawAddress == 'null') ? '' : rawAddress;

          final rawBlood = medical['blood_group']?.toString().trim() ?? '';
          final bloodGroup = (rawBlood == 'None' || rawBlood == 'null') ? '' : rawBlood;

          final rawCondition = medical['condition']?.toString().trim() ?? '';
          final condition = (rawCondition == 'None' || rawCondition == 'null') ? '' : rawCondition;

          final rawAllergies = medical['allergies']?.toString().trim() ?? '';
          final allergies = (rawAllergies == 'None' || rawAllergies == 'null') ? '' : rawAllergies;

          final totalVisits = int.tryParse(medical['total_visits']?.toString() ?? '0') ?? 0;

          final initialReg = visitHistory['initial_registration']?.toString() ?? '';
          final lastVisit = visitHistory['last_check_in_visit']?.toString() ?? '';
          final nextAppt = visitHistory['next_scheduled_appointment']?.toString();

          final policyName = insurance['policy_name']?.toString() ?? insurance['provider']?.toString() ?? '';
          final policyNumber = insurance['policy_number']?.toString() ?? insurance['number']?.toString() ?? '';

          final resolvedName = (patientName != null && patientName.trim().isNotEmpty)
              ? patientName.trim()
              : (data['name']?.toString() ?? 'Patient');

          return PatientProfileEntity(
            id: patientId,
            name: resolvedName,
            dob: '',
            gender: '',
            bloodGroup: bloodGroup,
            phone: phone,
            email: email,
            address: address,
            emergencyContactName: emergency['name']?.toString() ?? '',
            emergencyContactPhone: emergency['phone']?.toString() ?? '',
            condition: condition,
            allergies: allergies,
            totalVisits: totalVisits,
            registrationDate: initialReg,
            lastVisitDate: lastVisit,
            nextAppointment: (nextAppt == 'None' || nextAppt == null) ? null : nextAppt,
            summary: condition,
            policyName: (policyName == 'None' || policyName.isEmpty) ? null : policyName,
            policyNumber: (policyNumber == 'None' || policyNumber.isEmpty) ? null : policyNumber,
          );
        }
      }
    } catch (_) {
      // Fallback below
    }

    final String nameToUse = (patientName != null && patientName.trim().isNotEmpty)
        ? patientName.trim()
        : 'Patient $patientId';

    return PatientProfileEntity(
      id: patientId,
      name: nameToUse,
      dob: '',
      gender: '',
      bloodGroup: '',
      phone: '',
      email: '',
      address: '',
      emergencyContactName: '',
      emergencyContactPhone: '',
      condition: '',
      allergies: '',
      totalVisits: 0,
      registrationDate: '',
      lastVisitDate: '',
      nextAppointment: null,
      summary: '',
    );
  }
}