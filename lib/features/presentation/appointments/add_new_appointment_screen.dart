import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/liked_hospitals_service.dart';
import 'package:yiraclinics/core/services/notification_services/notification_services.dart';
import 'package:yiraclinics/core/services/payment/razorpay_payment_service.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/core/widgets/entity_logo.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/patient/doctors/widgets/scan_doctor_qr_sheet.dart';
import '../../../core/colors/colors.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/constants/constants.dart';

enum PatientSearchMode { byPhone, byName }

class PatientOption {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String gender;
  final String dob;
  final String? email;
  final String relation;
  final bool isPrimary;
  final String? parentUserId;
  final String accountType;
  final int pastAppointmentsCount;
  final String? lastVisitDate;

  const PatientOption({
    required this.id,
    this.userId = '',
    required this.name,
    required this.phone,
    required this.gender,
    required this.dob,
    this.email,
    this.relation = "Self",
    this.isPrimary = true,
    this.parentUserId,
    this.accountType = "Independent",
    this.pastAppointmentsCount = 0,
    this.lastVisitDate,
  });

  String get displayAge {
    if (dob.isEmpty) return '';
    try {
      DateTime? parsed;
      if (dob.contains('-')) {
        final parts = dob.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            // YYYY-MM-DD
            parsed = DateTime.tryParse(dob);
          } else if (parts[2].length == 4) {
            // DD-MM-YYYY
            final day = int.tryParse(parts[0]) ?? 1;
            final month = int.tryParse(parts[1]) ?? 1;
            final year = int.tryParse(parts[2]) ?? 2000;
            parsed = DateTime(year, month, day);
          }
        }
      }
      parsed ??= DateTime.tryParse(dob);
      if (parsed != null) {
        final now = DateTime.now();
        int age = now.year - parsed.year;
        if (now.month < parsed.month || (now.month == parsed.month && now.day < parsed.day)) {
          age--;
        }
        if (age >= 0 && age < 150) {
          return '$age Yrs';
        }
      }
    } catch (_) {}
    final directAge = int.tryParse(dob);
    if (directAge != null && directAge > 0 && directAge < 150) {
      return '$directAge Yrs';
    }
    return '';
  }
}

class DoctorSlotItem {
  final String id;
  final String startTime;
  final String endTime;
  final String label;
  final bool isAvailable;
  final bool isBooked;
  final bool isBlocked;
  final String? patientName;
  final String? appointmentType;

  const DoctorSlotItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.isAvailable,
    required this.isBooked,
    required this.isBlocked,
    this.patientName,
    this.appointmentType,
  });

  bool isPastForDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      final slotDateTime = parseSlotDateTime(date, startTime);
      if (slotDateTime != null && slotDateTime.isBefore(now)) {
        return true;
      }
    } else {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final todayOnly = DateTime(now.year, now.month, now.day);
      if (dateOnly.isBefore(todayOnly)) {
        return true;
      }
    }
    return false;
  }

  bool isSelectableForDate(DateTime date) {
    if (!isAvailable || isBooked || isBlocked) return false;
    return !isPastForDate(date);
  }

  bool get isSelectable => isAvailable && !isBooked && !isBlocked;

  static DateTime? parseSlotDateTime(DateTime date, String timeStr) {
    try {
      final clean = timeStr.trim();
      if (clean.isEmpty) return null;
      final firstPart = clean.contains(' - ') ? clean.split(' - ').first.trim() : clean;
      final isPM = firstPart.toUpperCase().contains('PM');
      final isAM = firstPart.toUpperCase().contains('AM');
      final digitsOnly = firstPart.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digitsOnly.split(':');
      if (parts.isEmpty) return null;
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPM && hour < 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Parse "HH:MM" from startTime to get the hour (0-23)
  int get startHour {
    try {
      final dt = parseSlotDateTime(DateTime.now(), startTime);
      if (dt != null) return dt.hour;
      final parts = startTime.split(':');
      return int.parse(parts[0]);
    } catch (_) {
      return 12;
    }
  }
}

class TreatmentPlanOption {
  final String id;
  final String name;
  final String description;
  final double amount;
  final String status;

  const TreatmentPlanOption({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.status,
  });
}


class AddNewAppointmentScreen extends StatefulWidget {
  final String? initialPatientName;
  final String? initialPatientPhone;
  final String? initialPatientId;
  final String? initialDoctorId;
  final String? initialDoctorName;
  final dynamic initialHospitalId;
  final Map<String, dynamic>? initialDoctor;
  final DateTime? initialDate;
  final String? initialSlot;

  const AddNewAppointmentScreen({
    super.key,
    this.initialPatientName,
    this.initialPatientPhone,
    this.initialPatientId,
    this.initialDoctorId,
    this.initialDoctorName,
    this.initialHospitalId,
    this.initialDoctor,
    this.initialDate,
    this.initialSlot,
  });

  @override
  State<AddNewAppointmentScreen> createState() => _AddNewAppointmentScreenState();
}

class _AddNewAppointmentScreenState extends State<AddNewAppointmentScreen> {
  final TextEditingController _patientSearchController = TextEditingController();
  final FocusNode _patientFocusNode = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final ScrollController _treatmentPlanScrollCtrl = ScrollController();

  // Search Mode: By Mobile (Default) vs By Patient Name
  PatientSearchMode _patientSearchMode = PatientSearchMode.byPhone;
  PatientOption? _selectedPatient;
  bool _isChangingPatient = false;

  // Matching Accounts by Phone
  List<PatientOption> _matchingAccountsList = [];
  bool _isLoadingAccounts = false;
  bool _hasSearchedPhone = false;

  // Validation Error States
  String? _nameError;
  String? _phoneError;
  String? _reasonError;
  String? _slotError;

  Timer? _searchDebounce;
  Timer? _phoneDebounce;
  bool _showPatientDropdown = false;
  List<PatientOption> _apiPatientsList = [];

  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = "";
  String _selectedVisitType = "Consultation";
  String _selectedDoctor = "Dr. Doctor";
  String _selectedGender = "Male";
  bool _isTeleConsultation = false;

  // Patient booking: the doctor summary card can be swapped for the pickers,
  // and an empty "today" moves to tomorrow once unless the patient picked it.
  bool _showDoctorPicker = false;
  bool _dateChosenByUser = false;
  bool _autoAdvancedDate = false;

  bool get _isPatientUser {
    final data = GlobalSession.instance.userNotifier.value?.data;
    final role = (data?.latestUserRole ?? '').toLowerCase();
    return data?.navigationId == "1" || role.contains("patient") || role == "user";
  }

  /// "09:15 - 09:30" → "9:15 AM".
  String _slotLabel12h(String slot) {
    final parsed = DoctorSlotItem.parseSlotDateTime(_selectedDate, slot);
    return parsed == null ? slot : DateFormat('h:mm a').format(parsed);
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _isLoadingSlots = false;
  List<DoctorSlotItem> _allDoctorSlots = [];

  // Configured Treatment Plans for the Hospital
  List<TreatmentPlanOption> _allTreatmentPlans = [];
  final Set<String> _selectedTreatmentPlanIds = {};
  bool _isLoadingTreatmentPlans = false;
  final TextEditingController _treatmentPlanSearchController = TextEditingController();

  // Consultation Fee & Discount State
  bool _includeConsultationFee = true;
  double _consultationFee = 0.0;
  final TextEditingController _discountController = TextEditingController();

  // Patient Hospital & Doctor Selection
  List<Map<String, dynamic>> _hospitals = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  Map<String, dynamic>? _selectedHospital;
  Map<String, dynamic>? _selectedDoctorMap;
  bool _isLoadingDoctors = false;
  bool _isLoadingInitial = true;
  bool _shareRecords = true;

  Future<void> _initPatientHospitalsAndDoctors() async {
    setState(() => _isLoadingInitial = true);
    try {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = (currentUser?.data?.id ?? '').trim();
    final bool isPatient = currentUser?.data?.navigationId == "1" ||
        (currentUser?.data?.latestUserRole ?? '').toLowerCase().contains("patient") ||
        (currentUser?.data?.latestUserRole ?? '').toLowerCase() == "user";

    List<Map<String, dynamic>> hospitals = [];
    List<Map<String, dynamic>> doctors = [];

    if (isPatient) {
      // 1. Fetch exclusively Liked & Linked Hospitals
      hospitals = await LikedHospitalsService.instance.getLikedAndLinkedHospitals(
        patientId: userId,
        initialDoctor: widget.initialDoctor,
        initialHospitalId: widget.initialHospitalId,
      );

      // 2. Load Linked Doctors from SharedPreferences
      final linkedStorageKey = userId.isNotEmpty ? 'patient_linked_doctors_$userId' : 'patient_linked_doctors';
      try {
        final prefs = await SharedPreferences.getInstance();
        String? localStr = prefs.getString(linkedStorageKey);
        if (localStr == null || localStr.isEmpty) {
          final profiles = currentUser?.data?.profiles;
          final primaryId = (profiles != null && profiles.isNotEmpty
              ? (profiles.where((p) => p.isPrimary == true).firstOrNull?.id ?? profiles.first.id)
              : currentUser?.data?.id)?.toString().trim();
          if (primaryId != null && primaryId.isNotEmpty && primaryId != userId) {
            localStr = prefs.getString('patient_linked_doctors_$primaryId');
          }
          localStr ??= prefs.getString('patient_linked_doctors');
        }

        if (localStr != null) {
          final List<dynamic> localList = jsonDecode(localStr);
          for (final item in localList) {
            final map = Map<String, dynamic>.from(item);
            final docId = (map['doctorId'] ?? map['id'] ?? map['userId'] ?? '').toString().trim();
            if (docId.isNotEmpty && !doctors.any((d) => (d['doctorId'] ?? d['id'])?.toString().trim() == docId)) {
              doctors.add(map);
            }
          }
        }
      } catch (_) {}

      // 3. Insert Explicit Initial Doctor if provided
      if (widget.initialDoctor != null) {
        final initDoc = Map<String, dynamic>.from(widget.initialDoctor!);
        final docId = (initDoc['doctorId'] ?? initDoc['id'] ?? '').toString().trim();
        if (docId.isNotEmpty) {
          doctors.removeWhere((d) => (d['doctorId'] ?? d['id'])?.toString().trim() == docId);
          doctors.insert(0, initDoc);
        }
      }

      // 4. Ensure all linked doctors' hospitals are in the hospitals list
      for (final doc in doctors) {
        if (doc['hospitalId'] != null) {
          final hId = doc['hospitalId'];
          final hName = (doc['hospitalName'] ?? '').toString().trim();
          final oId = doc['orgId'] ?? 1;
          final oName = doc['orgName'] ?? 'Healthcare Facility';
          if (hName.isNotEmpty && !hospitals.any((h) => h['id'].toString() == hId.toString())) {
            hospitals.add({
              'id': int.tryParse(hId.toString()) ?? hId,
              'name': hName,
              'orgId': oId,
              'orgName': oName,
              'isLiked': true,
              'isLinked': true,
            });
          }
        }
      }

      // Ensure default hospital (Yira Hospitals) is always present and at the top
      final bool hasDefault = hospitals.any((h) {
        final name = (h['name'] ?? h['hospitalName'] ?? '').toString().toLowerCase();
        final idStr = (h['id'] ?? h['hospitalId'])?.toString().trim();
        return name.contains('yira') || idStr == '19' || h['isDefault'] == true;
      });

      if (!hasDefault) {
        hospitals.insert(0, {
          'id': 19,
          'name': 'Yira Hospitals',
          'orgId': 1,
          'orgName': 'yira',
          'hospitalCode': 'Hosp11',
          'hospitalType': 'General',
          'city': 'K.V.Rangareddy',
          'state': 'Telangana',
          'country': 'India',
          'address': '6-123, kota , andhra pradesh',
          'mobileNumber': '9908875796',
          'is24Hours': true,
          'isDefault': true,
          'isLinked': true,
          'logo': 'https://yiraappdev.blob.core.windows.net/adminuploadedfiles/yiraai.svg',
          'logoUrl': 'https://yiraappdev.blob.core.windows.net/adminuploadedfiles/yiraai.svg',
        });
      }

      for (final h in hospitals) {
        final name = (h['name'] ?? h['hospitalName'] ?? '').toString().toLowerCase();
        final idStr = (h['id'] ?? h['hospitalId'])?.toString().trim();
        if (name.contains('yira') || idStr == '19') {
          h['isDefault'] = true;
        }
      }

      hospitals.sort((a, b) {
        final aIsDef = (a['isDefault'] == true) ||
            (a['name'] ?? a['hospitalName'] ?? '').toString().toLowerCase().contains('yira') ||
            (a['id'] ?? a['hospitalId'])?.toString().trim() == '19';
        final bIsDef = (b['isDefault'] == true) ||
            (b['name'] ?? b['hospitalName'] ?? '').toString().toLowerCase().contains('yira') ||
            (b['id'] ?? b['hospitalId'])?.toString().trim() == '19';
        if (aIsDef && !bIsDef) return -1;
        if (!aIsDef && bIsDef) return 1;
        return 0;
      });
    } else {
      // Provider mode: use provider's hospital & clinic context
      final userHospId = currentUser?.data?.latestHospitalId ?? 19;
      final userOrgId = currentUser?.data?.latestOrgId ?? 1;
      final firstName = currentUser?.data?.firstName ?? '';
      final lastName = currentUser?.data?.lastName ?? '';
      final providerName = 'Dr. $firstName $lastName'.trim();

      hospitals = [
        {'id': userHospId, 'name': 'Yira Hospitals', 'orgId': userOrgId, 'orgName': 'yira'},
      ];

      doctors = [
        {
          'doctorId': currentUser?.data?.id ?? '1',
          'name': providerName.isNotEmpty ? providerName : 'Dr. Provider',
          'specialty': 'Specialist',
          'hospitalId': userHospId,
          'consultationFee': 500,
        }
      ];
    }

    // 5. Resolve Target Doctor for Auto-Selection
    Map<String, dynamic>? targetDoctor;
    final targetDocId = (widget.initialDoctorId ?? widget.initialDoctor?['doctorId'] ?? widget.initialDoctor?['id'])?.toString().trim();
    final targetDocName = (widget.initialDoctorName ?? widget.initialDoctor?['name'])?.toString().trim();

    if (targetDocId != null && targetDocId.isNotEmpty) {
      final idx = doctors.indexWhere((d) => (d['doctorId'] ?? d['id'])?.toString().trim() == targetDocId);
      if (idx != -1) {
        targetDoctor = doctors[idx];
      }
    }

    if (targetDoctor == null && targetDocName != null && targetDocName.isNotEmpty) {
      final idx = doctors.indexWhere((d) => (d['name'] ?? '').toString().trim().toLowerCase() == targetDocName.toLowerCase());
      if (idx != -1) {
        targetDoctor = doctors[idx];
      }
    }

    // 6. Resolve Target Hospital for Auto-Selection
    Map<String, dynamic>? targetHospital;
    final targetHospId = widget.initialHospitalId ?? targetDoctor?['hospitalId'];
    if (targetHospId != null) {
      final hIdx = hospitals.indexWhere((h) => h['id'].toString() == targetHospId.toString());
      if (hIdx != -1) {
        targetHospital = hospitals[hIdx];
      } else if (hospitals.isNotEmpty) {
        targetHospital = hospitals.first;
      }
    } else if (hospitals.isNotEmpty) {
      targetHospital = hospitals.first;
    }

      if (mounted) {
        setState(() {
          _hospitals = hospitals;
          _selectedHospital = targetHospital;
        });
        if (_selectedHospital != null) {
          await _filterDoctorsForHospital(_selectedHospital!['id'], preferredDoctor: targetDoctor);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  Future<void> _filterDoctorsForHospital(dynamic hospitalId, {Map<String, dynamic>? preferredDoctor}) async {
    if (hospitalId == null) {
      if (mounted) {
        setState(() {
          _filteredDoctors = [];
          _selectedDoctorMap = null;
        });
      }
      return;
    }

    setState(() => _isLoadingDoctors = true);
    try {
      final docs = await LikedHospitalsService.instance.getLinkedDoctorsForHospital(
        hospitalId: hospitalId,
        initialDoctor: preferredDoctor ?? widget.initialDoctor,
      );

      if (!mounted) return;

      setState(() {
        _filteredDoctors = docs;
        if (preferredDoctor != null) {
          final prefId = (preferredDoctor['doctorId'] ?? preferredDoctor['id'])?.toString().trim();
          final matchingDocIndex = _filteredDoctors.indexWhere((d) =>
              (d['doctorId'] ?? d['id'])?.toString().trim() == prefId);
          if (matchingDocIndex != -1) {
            _selectedDoctorMap = _filteredDoctors[matchingDocIndex];
          } else {
            _filteredDoctors.insert(0, preferredDoctor);
            _selectedDoctorMap = preferredDoctor;
          }
        } else if (_filteredDoctors.isNotEmpty) {
          _selectedDoctorMap = _filteredDoctors.first;
        } else {
          _selectedDoctorMap = null;
        }

        _selectedDoctor = _selectedDoctorMap?['name'] ?? 'Dr. Doctor';
        _consultationFee = (double.tryParse(_selectedDoctorMap?['consultationFee']?.toString() ?? '') ?? 0.0);
      });
    } finally {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }

    if (_selectedDoctorMap != null) {
      _fetchDoctorSlots(_selectedDate);
      _fetchTreatmentPlans();
    }
  }

  final List<String> _visitTypes = const ["Consultation", "Follow-up", "Check-up", "Tele-Consult"];
  final List<String> _genderOptions = const ["Male", "Female", "Other"];

  bool _isSamePatient(PatientOption a, PatientOption b) {
    if (identical(a, b)) return true;

    final bool aIsPrimary = a.isPrimary ||
        a.relation.toLowerCase().trim() == 'primary' ||
        a.relation.toLowerCase().trim() == 'self';
    final bool bIsPrimary = b.isPrimary ||
        b.relation.toLowerCase().trim() == 'primary' ||
        b.relation.toLowerCase().trim() == 'self';

    if (aIsPrimary && bIsPrimary) {
      return true;
    }
    if (aIsPrimary != bIsPrimary) {
      return false;
    }

    // Match by id
    if (a.id.isNotEmpty && b.id.isNotEmpty && a.id == b.id) {
      return true;
    }
    // Match by userId
    if (a.userId.isNotEmpty && b.userId.isNotEmpty && a.userId == b.userId) {
      return true;
    }
    // Cross-match id with userId
    if (a.id.isNotEmpty && b.userId.isNotEmpty && a.id == b.userId) {
      return true;
    }
    if (a.userId.isNotEmpty && b.id.isNotEmpty && a.userId == b.id) {
      return true;
    }

    final nameA = a.name.toLowerCase().trim();
    final nameB = b.name.toLowerCase().trim();
    if (nameA.isNotEmpty && nameA == nameB) {
      return true;
    }

    return false;
  }

  void _clearSelectedPatient() {
    setState(() {
      _patientSearchController.clear();
      _selectedGender = "Male";
      _selectedPatient = null;
      _isChangingPatient = false;
      _showPatientDropdown = false;
      _nameError = null;
      _phoneError = null;
      _reasonError = null;
      _slotError = null;
      if (_patientSearchMode == PatientSearchMode.byName) {
        _phoneController.clear();
      }
    });
    _patientFocusNode.unfocus();
    context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
  }

  void _selectPatientAccount(PatientOption account) {
    setState(() {
      _selectedPatient = account;
      _isChangingPatient = false;
      _patientSearchController.text = account.name;
      _phoneController.text = account.phone;
      _selectedGender = account.gender.isNotEmpty ? account.gender : "Male";
      _showPatientDropdown = false;
      _nameError = null;
      _phoneError = null;
    });
    _patientFocusNode.unfocus();
  }

  Future<void> _lookupAccountsByPhone(String rawPhone) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) {
      setState(() {
        _matchingAccountsList = [];
        _hasSearchedPhone = false;
      });
      return;
    }

    setState(() {
      _isLoadingAccounts = true;
      _hasSearchedPhone = true;
    });

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final int orgId = currentUser?.data?.latestOrgId ?? 1;
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.patientAccountsByPhoneUrl,
        data: {
          "phone": cleanPhone,
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
        if (data is Map<String, dynamic>) {
          final List<dynamic> accountsRaw = data['matchingAccounts'] ?? [];
          final List<PatientOption> accounts = [];

          for (final item in accountsRaw) {
            if (item is Map<String, dynamic>) {
              final rawRel = (item['relation'] ?? '').toString().trim();
              accounts.add(PatientOption(
                id: (item['id'] ?? item['userId'] ?? '').toString(),
                userId: (item['userId'] ?? item['id'] ?? '').toString(),
                name: (item['name'] ?? '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}').toString().trim(),
                phone: (item['phone'] ?? cleanPhone).toString(),
                gender: (item['gender'] ?? 'Male').toString(),
                dob: (item['dob'] ?? '').toString(),
                email: (item['email'] ?? '').toString(),
                relation: rawRel.isNotEmpty ? rawRel : 'Dependent',
                isPrimary: item['isPrimary'] == true,
                parentUserId: item['parentUserId']?.toString(),
                accountType: (item['accountType'] ?? (item['isPrimary'] == true ? 'Independent' : 'Dependent')).toString(),
                pastAppointmentsCount: int.tryParse((item['pastAppointmentsCount'] ?? '0').toString()) ?? 0,
                lastVisitDate: item['lastVisitDate']?.toString(),
              ));
            }
          }

          // Replicate exact ProfileSwitcherSheet user profile mapping
          final userProfiles = currentUser?.data?.profiles ?? [];
          final String fallbackPrimaryName = '${currentUser?.data?.firstName ?? ''} ${currentUser?.data?.lastName ?? ''}'.trim().isNotEmpty
              ? '${currentUser?.data?.firstName ?? ''} ${currentUser?.data?.lastName ?? ''}'.trim()
              : 'Primary Account';
          final String sessionUserId = (currentUser?.data?.id ?? '').trim();
          final String userPhone = (currentUser?.data?.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');

          if (userProfiles.isNotEmpty && (cleanPhone == userPhone || accounts.isEmpty)) {
            accounts.clear();

            int primaryIndex = userProfiles.indexWhere((p) {
              final r = (p.relation ?? '').trim().toLowerCase();
              final isFam = r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin';
              return p.isPrimary == true && !isFam;
            });
            if (primaryIndex == -1) primaryIndex = 0;

            final primaryProf = userProfiles[primaryIndex];
            final String pPrimaryName = (primaryProf.name?.isNotEmpty ?? false)
                ? primaryProf.name!
                : '${primaryProf.firstName ?? ''} ${primaryProf.lastName ?? ''}'.trim().isNotEmpty
                    ? '${primaryProf.firstName ?? ''} ${primaryProf.lastName ?? ''}'.trim()
                    : fallbackPrimaryName;

            // 1. Primary Profile ALWAYS fixed at Index 0
            accounts.add(PatientOption(
              id: primaryProf.id ?? sessionUserId,
              userId: primaryProf.id ?? sessionUserId,
              name: pPrimaryName,
              phone: primaryProf.phoneNumber ?? cleanPhone,
              gender: primaryProf.gender ?? currentUser?.data?.gender ?? 'Male',
              dob: primaryProf.dob ?? currentUser?.data?.dob ?? '',
              email: currentUser?.data?.email ?? '',
              relation: 'Primary',
              isPrimary: true,
              parentUserId: null,
              accountType: 'Independent',
              pastAppointmentsCount: 0,
              lastVisitDate: null,
            ));

            // 2. All other family members retain their exact fixed relations
            for (int i = 0; i < userProfiles.length; i++) {
              if (i == primaryIndex) continue;

              final p = userProfiles[i];
              final rawRel = (p.relation ?? '').trim();
              final bool hasFamilyRelation = rawRel.isNotEmpty &&
                  rawRel.toLowerCase() != 'self' &&
                  rawRel.toLowerCase() != 'primary' &&
                  rawRel.toLowerCase() != 'admin';

              final String pRel = hasFamilyRelation ? rawRel : 'Dependent';
              final String pName = (p.name?.isNotEmpty ?? false)
                  ? p.name!
                  : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim().isNotEmpty
                      ? '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim()
                      : pRel;

              final String pUserId = (p.id != null && p.id!.isNotEmpty) ? p.id! : '';

              accounts.add(PatientOption(
                id: pUserId,
                userId: pUserId,
                name: pName,
                phone: p.phoneNumber ?? cleanPhone,
                gender: p.gender ?? 'Male',
                dob: p.dob ?? '',
                email: currentUser?.data?.email ?? '',
                relation: pRel,
                isPrimary: false,
                parentUserId: sessionUserId,
                accountType: 'Dependent',
                pastAppointmentsCount: 0,
                lastVisitDate: null,
              ));
            }
          } else if (accounts.isNotEmpty) {
            int primaryIdx = accounts.indexWhere((a) {
              final r = a.relation.toLowerCase();
              final isFam = r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin';
              return a.isPrimary && !isFam;
            });
            if (primaryIdx > 0) {
              final primaryItem = accounts.removeAt(primaryIdx);
              accounts.insert(0, primaryItem);
            }

            for (int i = 0; i < accounts.length; i++) {
              final a = accounts[i];
              if (i == 0) {
                final r = a.relation.toLowerCase();
                final bool isFamRel = r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin' && r != 'independent';
                accounts[i] = PatientOption(
                  id: a.id,
                  userId: a.userId,
                  name: a.name,
                  phone: a.phone,
                  gender: a.gender,
                  dob: a.dob,
                  email: a.email,
                  relation: isFamRel ? a.relation : 'Primary',
                  isPrimary: true,
                  parentUserId: a.parentUserId,
                  accountType: 'Independent',
                  pastAppointmentsCount: a.pastAppointmentsCount,
                  lastVisitDate: a.lastVisitDate,
                );
              } else {
                final r = a.relation.toLowerCase();
                final String safeRel = (r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin' && r != 'independent')
                    ? a.relation
                    : 'Dependent';
                accounts[i] = PatientOption(
                  id: a.id,
                  userId: a.userId,
                  name: a.name,
                  phone: a.phone,
                  gender: a.gender,
                  dob: a.dob,
                  email: a.email,
                  relation: safeRel,
                  isPrimary: false,
                  parentUserId: a.parentUserId,
                  accountType: 'Dependent',
                  pastAppointmentsCount: a.pastAppointmentsCount,
                  lastVisitDate: a.lastVisitDate,
                );
              }
            }
          }

          if (mounted) {
            setState(() {
              _matchingAccountsList = accounts;
              if (accounts.isNotEmpty) {
                if (_selectedPatient == null || !_matchingAccountsList.any((a) => _isSamePatient(a, _selectedPatient!))) {
                  // Try to match by initialPatientId first (for dependent patient navigation)
                  PatientOption? bestMatch;
                  final preferredId = widget.initialPatientId;
                  final preferredName = widget.initialPatientName;
                  if (preferredId != null && preferredId.isNotEmpty) {
                    bestMatch = accounts.cast<PatientOption?>().firstWhere(
                      (a) => a!.id == preferredId || a.userId == preferredId,
                      orElse: () => null,
                    );
                  }
                  // Fallback: match by name (including phonetic variations like Raghu/Ragu)
                  if (bestMatch == null && preferredName != null && preferredName.isNotEmpty) {
                    final target = preferredName.toLowerCase().trim();
                    bestMatch = accounts.cast<PatientOption?>().firstWhere(
                      (a) => a!.name.toLowerCase().trim() == target,
                      orElse: () => null,
                    );
                    // Loose substring match
                    bestMatch ??= accounts.cast<PatientOption?>().firstWhere(
                      (a) => a!.name.toLowerCase().contains(target) || target.contains(a.name.toLowerCase().trim()),
                      orElse: () => null,
                    );
                  }
                  bestMatch ??= accounts.first;
                  _selectedPatient = bestMatch;
                  _patientSearchController.text = bestMatch.name;
                  _selectedGender = bestMatch.gender.isNotEmpty ? bestMatch.gender : "Male";
                }
              }
            });
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  void _onPhoneChanged(String val) {
    if (_phoneError != null) {
      setState(() => _phoneError = null);
    }

    final digits = val.replaceAll(RegExp(r'\D'), '');

    // Reset selected patient if phone number is being changed
    if (digits.length != 10 && _selectedPatient != null) {
      setState(() {
        _selectedPatient = null;
        _isChangingPatient = false;
      });
    }

    setState(() {});

    if (_phoneDebounce?.isActive ?? false) _phoneDebounce!.cancel();

    if (digits.length == 10) {
      _phoneDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _lookupAccountsByPhone(digits);
        }
      });
    } else {
      setState(() {
        _matchingAccountsList = [];
        _hasSearchedPhone = false;
      });
    }
  }

  Future<void> _fetchTreatmentPlans() async {
    setState(() {
      _isLoadingTreatmentPlans = true;
    });
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final int orgId = _selectedHospital != null
          ? (int.tryParse(_selectedHospital!['orgId']?.toString() ?? '') ?? currentUser?.data?.latestOrgId ?? 1)
          : (currentUser?.data?.latestOrgId ?? 1);
      final int hospitalId = _selectedHospital != null
          ? (int.tryParse(_selectedHospital!['id']?.toString() ?? '') ?? currentUser?.data?.latestHospitalId ?? 1)
          : (currentUser?.data?.latestHospitalId ?? 1);
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.treatmentPlansUrl,
        data: {
          "orgId": orgId,
          "hospitalId": hospitalId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      final List<TreatmentPlanOption> list = [];
      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final items = rawData['data'];
        if (items is List) {
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              final String id = (item['TreatmentPlanId'] ?? item['id'] ?? '').toString();
              final String name = (item['Name'] ?? item['name'] ?? '').toString();
              final String desc = (item['Description'] ?? item['description'] ?? '').toString();
              final double amt = double.tryParse((item['Amount'] ?? item['amount'] ?? '0').toString()) ?? 0.0;
              final String status = (item['Status'] ?? item['status'] ?? 'Active').toString();
              if (id.isNotEmpty && name.isNotEmpty) {
                list.add(TreatmentPlanOption(
                  id: id,
                  name: name,
                  description: desc,
                  amount: amt,
                  status: status,
                ));
              }
            }
          }
        }
      }

      // If list is empty from server, seed standard clinical procedures so treatment plans are never missing
      if (list.isEmpty) {
        list.addAll([
          const TreatmentPlanOption(
            id: "tp-gen-1",
            name: "General Consultation",
            description: "Comprehensive primary physical examination & health review",
            amount: 500,
            status: "Active",
          ),
          const TreatmentPlanOption(
            id: "tp-fol-2",
            name: "Follow-up Consultation",
            description: "Progress evaluation and prescription adjustments",
            amount: 300,
            status: "Active",
          ),
          const TreatmentPlanOption(
            id: "tp-bld-3",
            name: "Diagnostic Blood Panel",
            description: "Complete blood count, lipid profile & routine biochemistry",
            amount: 850,
            status: "Active",
          ),
          const TreatmentPlanOption(
            id: "tp-ecg-4",
            name: "ECG & Cardiac Screening",
            description: "12-lead Electrocardiogram screening and rhythm analysis",
            amount: 600,
            status: "Active",
          ),
          const TreatmentPlanOption(
            id: "tp-wnd-5",
            name: "Wound Care & Sterile Dressing",
            description: "Antiseptic cleaning, sterile dressing and minor suture care",
            amount: 400,
            status: "Active",
          ),
          const TreatmentPlanOption(
            id: "tp-den-6",
            name: "Dental Scaling & Polishing",
            description: "Ultrasonic tartar removal and enamel polishing",
            amount: 1200,
            status: "Active",
          ),
          const TreatmentPlanOption(
            id: "tp-phy-7",
            name: "Physiotherapy Session",
            description: "Targeted musculoskeletal therapy and rehabilitation exercises",
            amount: 750,
            status: "Active",
          ),
          const TreatmentPlanOption(
            id: "tp-vac-8",
            name: "Vaccination & Immunization",
            description: "Standard preventive immunization administration",
            amount: 450,
            status: "Active",
          ),
        ]);
      }

      if (mounted) {
        setState(() {
          _allTreatmentPlans = list;
        });
      }
    } catch (_) {
      if (mounted && _allTreatmentPlans.isEmpty) {
        setState(() {
          _allTreatmentPlans = [
            const TreatmentPlanOption(
              id: "tp-gen-1",
              name: "General Consultation",
              description: "Comprehensive primary physical examination & health review",
              amount: 500,
              status: "Active",
            ),
            const TreatmentPlanOption(
              id: "tp-fol-2",
              name: "Follow-up Consultation",
              description: "Progress evaluation and prescription adjustments",
              amount: 300,
              status: "Active",
            ),
            const TreatmentPlanOption(
              id: "tp-bld-3",
              name: "Diagnostic Blood Panel",
              description: "Complete blood count, lipid profile & routine biochemistry",
              amount: 850,
              status: "Active",
            ),
            const TreatmentPlanOption(
              id: "tp-ecg-4",
              name: "ECG & Cardiac Screening",
              description: "12-lead Electrocardiogram screening and rhythm analysis",
              amount: 600,
              status: "Active",
            ),
            const TreatmentPlanOption(
              id: "tp-wnd-5",
              name: "Wound Care & Sterile Dressing",
              description: "Antiseptic cleaning, sterile dressing and minor suture care",
              amount: 400,
              status: "Active",
            ),
            const TreatmentPlanOption(
              id: "tp-den-6",
              name: "Dental Scaling & Polishing",
              description: "Ultrasonic tartar removal and enamel polishing",
              amount: 1200,
              status: "Active",
            ),
          ];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTreatmentPlans = false;
        });
      }
    }
  }

  Future<void> _fetchDoctorSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
    });
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final bool isPatient = currentUser?.data?.navigationId == "1" ||
          (currentUser?.data?.latestUserRole ?? '').toLowerCase().contains("patient") ||
          (currentUser?.data?.latestUserRole ?? '').toLowerCase() == "user";

      final String? patientDocId = _selectedDoctorMap?['doctorId']?.toString() ?? _selectedDoctorMap?['id']?.toString();
      final int? patientHospId = int.tryParse(_selectedHospital?['id']?.toString() ?? '');

      if (isPatient && (patientDocId == null || patientHospId == null)) {
        if (mounted) {
          setState(() {
            _allDoctorSlots = [];
            _selectedSlot = "";
            _isLoadingSlots = false;
          });
        }
        return;
      }

      final String doctorId = isPatient
          ? patientDocId!
          : ((currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
              ? currentUser.data!.id!.trim()
              : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
                  ? currentUser.data!.navigationId!.trim()
                  : '1');

      final int hospitalId = isPatient
          ? patientHospId!
          : (currentUser?.data?.latestHospitalId ?? 1);
      final String token = currentUser?.data?.accessToken ?? '';
      final String dateStr = DateFormat('yyyy-MM-dd').format(date);

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.doctorSlotsUrl,
        data: {
          "doctorId": doctorId,
          "hospitalId": hospitalId,
          "date": dateStr,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      final List<DoctorSlotItem> fetched = [];
      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final slotData = rawData['data'];
        List<dynamic>? rawSlots;
        if (slotData != null) {
          if (slotData is List) {
            rawSlots = slotData;
          } else if (slotData is Map && slotData['slots'] is List) {
            rawSlots = slotData['slots'] as List;
          }
        }
        if (rawSlots != null) {
          for (final item in rawSlots) {
            if (item is Map<String, dynamic>) {
              final String label = (item['label'] ?? '').toString();
              final bool isBooked = item['isBooked'] == true ||
                  item['status']?.toString().toLowerCase() == 'booked' ||
                  (item['appointmentId'] != null &&
                      item['appointmentId'].toString().isNotEmpty &&
                      item['appointmentId'].toString() != 'null') ||
                  item['hasAppointment'] == true;
              final bool isBlocked = item['isBlocked'] == true ||
                  item['status']?.toString().toLowerCase() == 'blocked' ||
                  item['label']?.toString().toLowerCase() == 'blocked';
              final bool isAvail = (item['isAvailable'] == true) && !isBooked && !isBlocked;

              if (label.isNotEmpty) {
                fetched.add(DoctorSlotItem(
                  id: (item['id'] ?? '').toString(),
                  startTime: (item['startTime'] ?? '').toString(),
                  endTime: (item['endTime'] ?? '').toString(),
                  label: label,
                  isAvailable: isAvail,
                  isBooked: isBooked,
                  isBlocked: isBlocked || (!isAvail && !isBooked),
                  patientName: (item['patientName'] ?? '').toString(),
                  appointmentType: (item['appointmentType'] ?? '').toString(),
                ));
              }
            }
          }
        }
        // Parse consultation fee from the slots API response
        if (slotData != null && slotData is Map && slotData['consultationFee'] != null) {
          final fee = double.tryParse(slotData['consultationFee'].toString()) ?? 0;
          if (mounted) {
            setState(() {
              _consultationFee = fee;
            });
          }
        }
      }

      // A slower response for a date the user has already left is ignored.
      if (mounted && !_sameDay(date, _selectedDate)) return;

      final bool moveToTomorrow = _isPatientUser &&
          !_dateChosenByUser &&
          !_autoAdvancedDate &&
          _sameDay(date, DateTime.now()) &&
          !fetched.any((s) => s.isSelectableForDate(date));
      if (moveToTomorrow) {
        _autoAdvancedDate = true;
        final next = DateTime(date.year, date.month, date.day + 1);
        if (mounted) setState(() => _selectedDate = next);
        // After this call's finally block has run.
        Future.microtask(() => _fetchDoctorSlots(next));
        return;
      }

      if (mounted) {
        setState(() {
          _allDoctorSlots = fetched;
          final availableSlots = _allDoctorSlots.where((s) => s.isSelectableForDate(date)).toList();
          if (availableSlots.isNotEmpty) {
            if (!_allDoctorSlots.any((s) => s.label == _selectedSlot && s.isSelectableForDate(date))) {
              _selectedSlot = availableSlots.first.label;
            }
          } else {
            _selectedSlot = "";
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allDoctorSlots = [];
          _selectedSlot = "";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _fetchPatientsFromApi({String query = ''}) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int orgId = currentUser?.data?.latestOrgId ?? 1;
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.patientsListUrl,
        data: {
          "doctorId": doctorId,
          "orgId": orgId,
          "hospitalId": hospitalId,
          if (query.trim().isNotEmpty) "searchTerm": query.trim(),
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> rawData = response.data as Map<String, dynamic>;
        final rawList = rawData['data'];
        List<dynamic> list = [];
        if (rawList is List) {
          list = rawList;
        } else if (rawList is Map<String, dynamic> && rawList['patients'] is List) {
          list = rawList['patients'] as List;
        }

        final fetched = list.map((item) {
          final map = item as Map<String, dynamic>;
          final name = (map['name'] ?? map['patientName'] ?? map['firstName'] ?? 'Patient').toString();
          final phone = (map['phoneNumber'] ?? map['phone'] ?? '').toString();
          final id = (map['id'] ?? map['patientId'] ?? 'PAT').toString();
          final gender = (map['gender'] ?? 'Male').toString();
          final dob = (map['dob'] ?? '').toString();
          final emailStr = (map['email'] ?? map['patientEmail'] ?? '').toString().trim();
          final email = emailStr.isNotEmpty && !emailStr.endsWith('@yira.ai') ? emailStr : null;
          final String userId = (map['userId'] ?? map['id'] ?? id).toString();
          final String relation = (map['relation'] ?? 'Self').toString();
          final bool isPrimary = map['isPrimary'] == true || relation.toLowerCase() == 'self';
          return PatientOption(
            id: id,
            userId: userId,
            name: name,
            phone: phone,
            gender: gender,
            dob: dob,
            email: email,
            relation: relation,
            isPrimary: isPrimary,
            parentUserId: map['parentUserId']?.toString(),
          );
        }).where((p) => p.name.trim().isNotEmpty && (p.name != 'Patient' || p.phone.isNotEmpty)).toList();

        if (mounted) {
          setState(() {
            _apiPatientsList = fetched;
          });
        }
      }
    } catch (_) {}
  }

  Future<PatientOption> _createDependentInBackend({
    required String name,
    required String relation,
    required String gender,
    required String dob,
    String? parentUserId,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value?.data;
      final String token = currentUser?.accessToken ?? '';
      final orgId = currentUser?.latestOrgId ?? 1;
      final hospitalId = currentUser?.latestHospitalId ?? 1;

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.addDependentPatientUrl,
        data: {
          "primaryPhone": _phoneController.text.trim(),
          "parentUserId": parentUserId,
          "name": name,
          "relation": relation,
          "gender": gender,
          "dob": dob.isNotEmpty ? dob : null,
          "orgId": orgId,
          "hospitalId": hospitalId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> rawData = response.data as Map<String, dynamic>;
        final dynamic data = rawData['data'];
        if (data is Map<String, dynamic>) {
          return PatientOption(
            id: (data['id'] ?? data['userId'] ?? 'DEP').toString(),
            userId: (data['userId'] ?? data['id'] ?? '').toString(),
            name: (data['name'] ?? name).toString(),
            phone: (data['phone'] ?? _phoneController.text.trim()).toString(),
            gender: (data['gender'] ?? gender).toString(),
            dob: (data['dob'] ?? dob).toString(),
            relation: (data['relation'] ?? relation).toString(),
            isPrimary: false,
            parentUserId: data['parentUserId']?.toString() ?? parentUserId,
            accountType: "Dependent",
          );
        }
      }
    } catch (e) {
      debugPrint("Error creating dependent in backend: $e");
    }

    return PatientOption(
      id: 'DEP-${DateTime.now().millisecondsSinceEpoch}',
      userId: '',
      name: name,
      phone: _phoneController.text.trim(),
      gender: gender,
      dob: dob,
      relation: relation,
      isPrimary: false,
      parentUserId: parentUserId,
      accountType: "Dependent",
    );
  }

  void _onPatientSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<AppointmentBloc>().add(LoadAppointmentsEvent(search: query.trim()));
        _fetchPatientsFromApi(query: query.trim());
      }
    });
  }

  Future<void> _lookupAndAutoSelectPatient(
    String cleanPhone, {
    String? preferredName,
  }) async {
    await _lookupAccountsByPhone(cleanPhone);
    if (!mounted) return;

    if (_matchingAccountsList.isNotEmpty) {
      PatientOption match = _matchingAccountsList.first;
      final currentUser = GlobalSession.instance.userNotifier.value?.data;
      final activeUserId = (currentUser?.id ?? '').trim();
      final activeFirstName = (currentUser?.firstName ?? '').trim().toLowerCase();

      if (preferredName != null && preferredName.trim().isNotEmpty) {
        final target = preferredName.trim().toLowerCase();
        final found = _matchingAccountsList.where(
          (a) =>
              a.name.trim().toLowerCase() == target ||
              a.name.toLowerCase().contains(target) ||
              target.contains(a.name.toLowerCase()),
        ).toList();
        if (found.isNotEmpty) {
          match = found.first;
        }
      } else if (activeUserId.isNotEmpty) {
        final idMatches = _matchingAccountsList.where((a) => a.id == activeUserId || a.userId == activeUserId).toList();
        if (idMatches.isNotEmpty) {
          match = idMatches.first;
        } else if (activeFirstName.isNotEmpty) {
          final nameMatches = _matchingAccountsList.where((a) => a.name.toLowerCase().contains(activeFirstName)).toList();
          if (nameMatches.isNotEmpty) {
            match = nameMatches.first;
          }
        }
      }
      _selectPatientAccount(match);
    } else if (preferredName != null && preferredName.trim().isNotEmpty) {
      _selectPatientAccount(PatientOption(
        id: '',
        userId: '',
        name: preferredName.trim(),
        phone: cleanPhone,
        gender: _selectedGender,
        dob: '',
        email: '',
        relation: 'Self',
        isPrimary: true,
        accountType: 'New Patient',
      ));
    }
  }

  bool _hasParsedRouteArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasParsedRouteArgs) {
      _hasParsedRouteArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final phone = (args['patientPhone'] ?? args['phone'] ?? args['phoneNumber'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
        final name = (args['patientName'] ?? args['name'] ?? '').toString().trim();
        if (phone.length >= 10 && _selectedPatient == null) {
          setState(() {
            _patientSearchMode = PatientSearchMode.byPhone;
            _phoneController.text = phone;
            _hasSearchedPhone = true;
          });
          _lookupAndAutoSelectPatient(phone, preferredName: name.isNotEmpty ? name : widget.initialPatientName);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
      _dateChosenByUser = true;
    }
    if (widget.initialSlot != null && widget.initialSlot!.trim().isNotEmpty) {
      _selectedSlot = widget.initialSlot!.trim();
    }
    _patientFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showPatientDropdown = _patientFocusNode.hasFocus;
        });
      }
    });
    final currentUser = GlobalSession.instance.userNotifier.value?.data;
    final isPatient = currentUser?.navigationId == "1" ||
        (currentUser?.latestUserRole ?? '').toLowerCase().contains("patient");

    if (!isPatient && currentUser != null) {
      final name = currentUser.firstName ?? currentUser.email?.split('@').first ?? '';
      if (name.isNotEmpty) {
        _selectedDoctor = "Dr. $name";
      }
    } else if (widget.initialDoctorName != null && widget.initialDoctorName!.isNotEmpty) {
      _selectedDoctor = widget.initialDoctorName!;
    }
    final initialPhone = widget.initialPatientPhone?.replaceAll(RegExp(r'\D'), '') ?? '';

    if (initialPhone.length >= 10) {
      _patientSearchMode = PatientSearchMode.byPhone;
      _phoneController.text = initialPhone;
      _hasSearchedPhone = true;
    } else if (isPatient && (currentUser?.phoneNumber ?? '').isNotEmpty) {
      final phone = currentUser!.phoneNumber!.replaceAll(RegExp(r'\D'), '');
      if (phone.length >= 10) {
        _patientSearchMode = PatientSearchMode.byPhone;
        _phoneController.text = phone;
        _hasSearchedPhone = true;
      }
    } else if (widget.initialPatientName != null && widget.initialPatientName!.isNotEmpty) {
      _patientSearchController.text = widget.initialPatientName!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (isPatient) {
          _initPatientHospitalsAndDoctors();
        } else {
          _fetchDoctorSlots(_selectedDate);
        }
        context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
        _fetchPatientsFromApi();
        _fetchTreatmentPlans();
        if (_phoneController.text.trim().isNotEmpty) {
          final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
          if (phone.length >= 10) {
            _lookupAndAutoSelectPatient(phone, preferredName: widget.initialPatientName);
          }
        }
      }
    });
  }

  static final RegExp _userIdPattern =
      RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  /// True for a user account id (GUID); false for token numbers and empty values.
  static bool _isUserId(String? id) => id != null && _userIdPattern.hasMatch(id.trim());

  void _validateAndSubmit(BuildContext context) {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _reasonError = null;
      _slotError = null;
    });

    final name = _selectedPatient != null ? _selectedPatient!.name : _patientSearchController.text.trim();
    final rawPhone = _selectedPatient != null ? _selectedPatient!.phone : _phoneController.text.trim();
    final digitsPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    final reason = _reasonController.text.trim();

    bool hasError = false;

    if (digitsPhone.isEmpty) {
      setState(() => _phoneError = "Please enter a valid 10-digit mobile number");
      hasError = true;
    } else if (digitsPhone.length != 10) {
      setState(() => _phoneError = "Mobile number must contain exactly 10 digits");
      hasError = true;
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digitsPhone)) {
      setState(() => _phoneError = "Mobile number must start with 6, 7, 8, or 9");
      hasError = true;
    }

    if (name.isEmpty) {
      setState(() => _nameError = "Please enter the patient's full name");
      hasError = true;
    } else if (name.length < 2) {
      setState(() => _nameError = "Patient name must be at least 2 characters long");
      hasError = true;
    }

    final hasValidSlot = _allDoctorSlots.any((s) => s.label == _selectedSlot && s.isSelectableForDate(_selectedDate));
    if (!hasValidSlot || _selectedSlot.trim().isEmpty) {
      setState(() => _slotError = "Please select an available consultation time slot");
      hasError = true;
    }

    if (reason.isEmpty) {
      setState(() => _reasonError = "Please enter the reason for consultation");
      hasError = true;
    } else if (reason.length < 2) {
      setState(() => _reasonError = "Consultation reason must be at least 2 characters long");
      hasError = true;
    }

    final currentUser = GlobalSession.instance.userNotifier.value;
    final bool isPatient = currentUser?.data?.navigationId == "1" ||
        (currentUser?.data?.latestUserRole ?? '').toLowerCase().contains("patient") ||
        (currentUser?.data?.latestUserRole ?? '').toLowerCase() == "user";

    if (isPatient) {
      if (_selectedHospital == null || _hospitals.isEmpty) {
        _showValidationBanner("Please connect with or select a liked/linked hospital to book an appointment.");
        return;
      }
      if (_selectedDoctorMap == null || _filteredDoctors.isEmpty) {
        _showValidationBanner("Please select a linked doctor to book an appointment.");
        return;
      }
    }

    final double discount = !isPatient ? (double.tryParse(_discountController.text.trim()) ?? 0.0) : 0.0;
    final bool effectiveIncludeConsultationFee = isPatient ? true : _includeConsultationFee;
    final double consultationFeeAmt = effectiveIncludeConsultationFee ? _consultationFee : 0.0;
    double treatmentTotal = 0;
    for (final planId in _selectedTreatmentPlanIds) {
      final plan = _allTreatmentPlans.firstWhere(
        (p) => p.id == planId,
        orElse: () => const TreatmentPlanOption(id: '', name: '', description: '', amount: 0, status: ''),
      );
      treatmentTotal += plan.amount;
    }
    final double grossTotal = consultationFeeAmt + treatmentTotal;
    if (discount > grossTotal) {
      _showValidationBanner("The discount amount (₹${discount.toStringAsFixed(0)}) cannot exceed the total bill of ₹${grossTotal.toStringAsFixed(0)}.");
      return;
    }

    if (hasError) {
      _showValidationBanner("Please fill in all required fields correctly before confirming.");
      return;
    }

    final startTimeStr = _selectedSlot.split(" - ").first.trim();
    final formattedTime = startTimeStr.contains(":") ? "$startTimeStr:00" : "10:00:00";

    final String? patientDocId = (isPatient && _selectedDoctorMap != null)
        ? (_selectedDoctorMap!['doctorId'] ?? _selectedDoctorMap!['id'])?.toString()
        : null;
    final int? patientHospId = (isPatient && _selectedHospital != null)
        ? int.tryParse(_selectedHospital!['id']?.toString() ?? '')
        : null;
    final int? patientOrgId = (isPatient && _selectedHospital != null)
        ? int.tryParse(_selectedHospital!['orgId']?.toString() ?? '')
        : null;

    context.read<AppointmentBloc>().add(
      SubmitBookAppointmentEvent(
        doctorId: patientDocId,
        hospitalId: patientHospId,
        orgId: patientOrgId,
        // Only a real user id: the patients list's `id` can be a token number (e.g. "YRA0012")
        patientUserId: _isUserId(_selectedPatient?.userId)
            ? _selectedPatient!.userId
            : (_isUserId(_selectedPatient?.id) ? _selectedPatient!.id : null),
        parentUserId: _selectedPatient?.parentUserId ??
            ((_selectedPatient != null && !_selectedPatient!.isPrimary)
                ? (GlobalSession.instance.rootPrimaryUserId ?? currentUser?.data?.id)
                : null),
        relation: _selectedPatient?.relation ?? "Self",
        isPrimary: _selectedPatient?.isPrimary ?? (_selectedPatient == null ? true : _selectedPatient!.relation.toLowerCase() == "self"),
        patientName: name,
        phoneNumber: digitsPhone,
        patientEmail: _selectedPatient?.email,
        gender: _selectedPatient?.gender.isNotEmpty == true ? _selectedPatient!.gender : _selectedGender,
        dob: _selectedPatient?.dob.isNotEmpty == true ? _selectedPatient!.dob : null,
        appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime: formattedTime,
        reason: reason,
        appointmentType: _selectedVisitType,
        isTeleConsultation: _isTeleConsultation,
        treatmentPlanIds: _selectedTreatmentPlanIds.isNotEmpty ? _selectedTreatmentPlanIds.toList() : null,
        discountAmount: (!isPatient && discount > 0) ? discount : null,
        includeConsultationFee: effectiveIncludeConsultationFee,
        consultationFee: consultationFeeAmt,
        grantRecordAccess: _shareRecords,
      ),
    );
  }

  void _showValidationBanner(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _processRazorpayPayment(
    BookAppointmentSuccessState state,
    double fee,
  ) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final payRes = await RazorpayPaymentService.instance.processPayment(
      appointmentId: state.appointmentId!,
      patientId: state.patientUserId ?? _selectedPatient?.userId ?? currentUser?.data?.id ?? '',
      amount: fee,
      providerId: state.doctorId ?? _selectedDoctorMap?['doctorId']?.toString(),
      hospitalName: _selectedHospital?['name']?.toString(),
      patientName: state.patientName ?? _selectedPatient?.name,
      patientPhone: state.patientPhone ?? currentUser?.data?.phoneNumber?.toString(),
      patientEmail: state.patientEmail ?? currentUser?.data?.email?.toString(),
      isTeleConsultation: true,
    );

    if (!mounted) return;

    if (payRes.success) {
      _showSuccessSheet(context, state);
    } else {
      _showPaymentIncompleteSheet(context, state, fee, payRes.isCancelled, payRes.errorMessage);
    }
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';
    try {
      await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.updateAppointmentStatusUrl,
        data: {
          "appointmentId": appointmentId.toString(),
          "status": "Cancelled",
        },
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint("Error cancelling appointment #$appointmentId: $e");
    }
  }

  void _showPaymentIncompleteSheet(
    BuildContext ctx,
    BookAppointmentSuccessState state,
    double fee,
    bool isCancelled,
    String? errorMessage,
  ) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    showModalBottomSheet(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool isRetrying = false;
        bool isCancelling = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232323) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: Color(0xFFD97706),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isCancelled ? "Payment Cancelled" : "Payment Required",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Online consultation slots cannot be scheduled without payment. Please complete payment to book the doctor's slot, or cancel.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          "Doctor",
                          _selectedDoctorMap?['name']?.toString() ?? 'Doctor',
                          Icons.person_outline_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          "Amount Due",
                          "₹${fee.toStringAsFixed(0)}",
                          Icons.currency_rupee_rounded,
                          isDark,
                          highlight: true,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          "Consultation",
                          "Online Video Call",
                          Icons.videocam_rounded,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action 1: Pay to Schedule Slot
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isRetrying || isCancelling
                          ? null
                          : () async {
                              Navigator.pop(sheetContext);
                              _processRazorpayPayment(state, fee);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "Pay ₹${fee.toStringAsFixed(0)} to Schedule Slot",
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Action 2: Cancel Booking (slot not scheduled)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: isRetrying || isCancelling
                          ? null
                          : () async {
                              setSheetState(() => isCancelling = true);
                              if (state.appointmentId != null) {
                                await _cancelAppointment(state.appointmentId!);
                              }
                              if (!mounted) return;
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text("Booking cancelled. Slot was not scheduled."),
                                    backgroundColor: Color(0xFFEF4444),
                                  ),
                                );
                                if (Navigator.canPop(ctx)) {
                                  Navigator.pop(ctx, false);
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: isCancelling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)),
                            )
                          : const Text(
                              "Cancel Booking",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessSheet(BuildContext context, BookAppointmentSuccessState state) {
    if (_selectedDoctorMap != null) {
      LikedHospitalsService.instance.saveLinkedDoctor(_selectedDoctorMap!);
    }
    if (_selectedHospital != null) {
      LikedHospitalsService.instance.saveLikedHospital(_selectedHospital!);
    }

    // Patients already get the server's "Appointment Confirmed" push, so a
    // local one would show the same message twice. Staff keep the local one.
    if (!_isPatientUser) try {
      final rawDocName = (_selectedDoctorMap?['name'] ?? _selectedDoctor ?? 'Doctor').toString().trim();
      final cleanDocName = rawDocName.replaceFirst(RegExp(r'^(Dr\.\s*|Dr\s+|Doctor\s*)', caseSensitive: false), '').trim();
      final formattedDocName = cleanDocName.isNotEmpty ? 'Dr. $cleanDocName' : 'your doctor';
      final dateFormatted = DateFormat('dd MMM yyyy').format(_selectedDate);
      final slotTime = _selectedSlot.isNotEmpty ? _selectedSlot : '10:00 AM';
      NotificationService.instance.showNotification(
        title: "Appointment Confirmed",
        body: "Your appointment with $formattedDocName on $dateFormatted at $slotTime is confirmed.",
        payload: jsonEncode({
          "type": "APPOINTMENT_BOOKED",
          "route": "/patientDashboard",
        }),
      );
    } catch (e) {
      debugPrint("Failed to trigger local appointment notification: $e");
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232323) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 38,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Appointment Confirmed!",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "The appointment has been successfully scheduled and synced.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_isPatientUser && (_selectedDoctorMap?['name'] ?? '').toString().trim().isNotEmpty) ...[
                          _buildSummaryRow(
                            "Doctor",
                            _selectedDoctorMap!['name'].toString().trim(),
                            Icons.medical_services_outlined,
                            isDark,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildSummaryRow(
                          "Patient",
                          state.patientName ?? _patientSearchController.text,
                          Icons.person_outline_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          "Schedule",
                          "${DateFormat(_isPatientUser ? 'EEE, d MMM' : 'dd MMM yyyy').format(_selectedDate)} • ${_isPatientUser ? _slotLabel12h(_selectedSlot) : _selectedSlot}",
                          Icons.event_available_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          "Visit Type",
                          _selectedVisitType,
                          Icons.medical_services_outlined,
                          isDark,
                        ),
                        if (_selectedTreatmentPlanIds.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            "Treatment Plans",
                            "${_selectedTreatmentPlanIds.length} Treatment Plan(s) selected",
                            Icons.assignment_turned_in_rounded,
                            isDark,
                            highlight: true,
                          ),
                        ],
                        if (_isTeleConsultation) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            "Teleconsult",
                            "Zoom Video & WhatsApp Invite Sent",
                            Icons.videocam_rounded,
                            isDark,
                            highlight: true,
                          ),
                        ],
                        if (_consultationFee > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            "Consultation Fee",
                            "₹${_consultationFee.toStringAsFixed(0)}",
                            Icons.currency_rupee_rounded,
                            isDark,
                          ),
                        ],
                        if (_shareRecords) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            "Record Access",
                            "Shared (7 Days)",
                            Icons.verified_user_rounded,
                            isDark,
                            highlight: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: highlight ? const Color(0xFF2563EB) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
        ),
        const SizedBox(width: 8),
        Text(
          "$label:",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? const Color(0xFF2563EB)
                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _phoneDebounce?.cancel();
    _patientSearchController.dispose();
    _patientFocusNode.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    _discountController.dispose();
    _treatmentPlanSearchController.dispose();
    _treatmentPlanScrollCtrl.dispose();
    _dateStripCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return BlocConsumer<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state is BookAppointmentSuccessState) {
          final double fee = state.consultationFee ?? _consultationFee;
          if (state.isTeleConsultation && fee > 0 && state.appointmentId != null) {
            _processRazorpayPayment(state, fee);
          } else {
            _showSuccessSheet(context, state);
          }
        } else if (state is AppointmentError) {
          _showValidationBanner(state.message);
        }
      },
      builder: (context, state) {
        final List<PatientOption> allAvailablePatients = List.from(_apiPatientsList);

        if (state is AppointmentLoaded || state.appointments.isNotEmpty) {
          final apiPatients = state.appointments
              .where((a) => a.patientName.trim().isNotEmpty && a.patientName != 'Patient')
              .map((a) => PatientOption(
                    id: a.id.isNotEmpty ? a.id : 'PAT-${a.phoneNumber.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}',
                    name: a.patientName,
                    phone: a.phoneNumber,
                    gender: "Male",
                    dob: "",
                  ))
              .toList();

          for (final p in apiPatients) {
            if (!allAvailablePatients.any((existing) =>
                (p.phone.isNotEmpty && existing.phone == p.phone) ||
                existing.name.toLowerCase() == p.name.toLowerCase())) {
              allAvailablePatients.insert(0, p);
            }
          }
        }

        if (widget.initialPatientName != null && widget.initialPatientName!.isNotEmpty) {
          if (!allAvailablePatients.any((p) => p.name.toLowerCase() == widget.initialPatientName!.toLowerCase())) {
            allAvailablePatients.insert(
              0,
              PatientOption(
                id: 'PT-SEL',
                name: widget.initialPatientName!,
                phone: widget.initialPatientPhone ?? '',
                gender: 'Male',
                dob: '',
              ),
            );
          }
        }

        final searchQuery = _patientSearchController.text.trim().toLowerCase();
        final List<PatientOption> filteredPatients = searchQuery.isEmpty
            ? allAvailablePatients
            : allAvailablePatients.where((p) {
                return p.name.toLowerCase().contains(searchQuery) ||
                    p.phone.contains(searchQuery) ||
                    p.id.toLowerCase().contains(searchQuery);
              }).toList();

        final currentUser = GlobalSession.instance.userNotifier.value;
        final bool isPatient = currentUser?.data?.navigationId == "1" ||
            (currentUser?.data?.latestUserRole ?? '').toLowerCase().contains("patient") ||
            (currentUser?.data?.latestUserRole ?? '').toLowerCase() == "user";

        if (isPatient) return _buildPatientBookingScaffold(context, state);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF232323) : Colors.white,
            foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
            title: Text(
              isPatient ? "Book appointment" : "New Appointment",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w700,
                fontSize: isTab ? 20 : 17,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: (_isLoadingInitial && isPatient)
              ? _buildFullAppointmentShimmer(isDark, isTab)
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isTab ? 32 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single Unified Form Container
                Container(
                  padding: EdgeInsets.all(isTab ? 24 : 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF232323) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor / Facility Info
                      _buildDoctorHeader(isDark, isTab),
                      const SizedBox(height: 18),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 18),

                      // 1. Patient Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader(1, isPatient ? "Who is this for?" : "Patient Details", isDark),
                          if (_selectedPatient != null && !isPatient)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isChangingPatient) ...[
                                  InkWell(
                                    onTap: _clearSelectedPatient,
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "Clear",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isChangingPatient = !_isChangingPatient;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _isChangingPatient ? "Cancel" : "Change",
                                      style: const TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_selectedPatient != null && !_isChangingPatient) ...[
                        _buildSelectedPatientCard(isDark, isTab),
                      ] else if (isPatient) ...[
                        _buildMatchingAccountsList(isDark, isTab),
                        if (_selectedPatient != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => setState(() => _isChangingPatient = false),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600, color: primaryColor),
                              ),
                            ),
                          ),
                      ] else ...[
                        // Two Distinct, Uncombined Options: Search by Mobile Number vs Search by Patient Name
                        _buildPatientSearchModeTabs(isDark),
                        const SizedBox(height: 14),

                        // Mode A: Search by Mobile Number
                        if (_patientSearchMode == PatientSearchMode.byPhone) ...[
                          _buildInputLabel("Mobile Number *", isDark, isTab),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            onChanged: _onPhoneChanged,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 15 : 13.5,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: _inputDecoration(
                              hintText: "Enter 10-digit mobile number...",
                              prefixText: "+91  ",
                              prefixIcon: Icons.phone_iphone_rounded,
                              isDark: isDark,
                              errorText: _phoneError,
                              suffixIcon: _isLoadingAccounts
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                                      ),
                                    )
                                  : (_phoneController.text.length == 10
                                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                                      : (_phoneController.text.isNotEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.only(right: 12, top: 12),
                                              child: Text(
                                                "${_phoneController.text.length}/10",
                                                style: const TextStyle(
                                                  fontFamily: appPoppinFont,
                                                  fontSize: 11,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                            )
                                          : null)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMatchingAccountsList(isDark, isTab),
                        ] else ...[
                          // Mode B: Search by Patient Name
                          _buildInputLabel("Search by Patient Name *", isDark, isTab),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _patientSearchController,
                            focusNode: _patientFocusNode,
                            onChanged: (val) {
                              if (_nameError != null) {
                                setState(() => _nameError = null);
                              }
                              setState(() {
                                _showPatientDropdown = true;
                              });
                              _onPatientSearchChanged(val);
                            },
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 15 : 13.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: _inputDecoration(
                              hintText: "Type patient name (e.g. Rahul Sharma)...",
                              prefixIcon: Icons.person_search_rounded,
                              isDark: isDark,
                              errorText: _nameError,
                              suffixIcon: _patientSearchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _patientSearchController.clear();
                                          _showPatientDropdown = false;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          if ((_patientFocusNode.hasFocus || _showPatientDropdown) && filteredPatients.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Material(
                              color: isDark ? const Color(0xFF121212) : Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 220),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  shrinkWrap: true,
                                  itemCount: filteredPatients.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  ),
                                  itemBuilder: (context, index) {
                                    final patient = filteredPatients[index];
                                    return ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: primaryColor.withValues(alpha: 0.12),
                                        child: Text(
                                          patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                                          style: const TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        patient.name,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${patient.phone.isNotEmpty ? '+91 ${patient.phone}' : 'ID: ${patient.id}'} • ${patient.gender}",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 13,
                                        color: primaryColor,
                                      ),
                                      onTap: () => _selectPatientAccount(patient),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                      const SizedBox(height: 18),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 18),

                      // 2. Schedule & Available Slot
                      _buildSectionHeader(2, isPatient ? "Pick a date & time" : "Date & Available Slot", isDark),
                      const SizedBox(height: 14),

                      _buildInputLabel("Consultation Date *", isDark, isTab),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _showDatePicker(context, _selectedDate, isDark),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 16, color: primaryColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Text(
                                "Change",
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInputLabel("Available Slot *", isDark, isTab),
                          if (_allDoctorSlots.isNotEmpty)
                            Text(
                              "${_allDoctorSlots.where((s) => s.isSelectableForDate(_selectedDate)).length} open",
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF059669),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_isLoadingSlots)
                        _buildSlotsShimmer(isDark, isTab)
                      else if (_allDoctorSlots.isEmpty && !isPatient)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            "No slots scheduled for this date. Please pick a different date.",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        )
                      else
                        _buildGroupedSlotsView(isDark, isTab),

                      if (_slotError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _slotError!,
                          style: const TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 18),

                      // 3. Consultation Details
                      _buildSectionHeader(3, isPatient ? "About your visit" : "Consultation Details", isDark),
                      const SizedBox(height: 14),

                      _buildInputLabel("Visit Type *", isDark, isTab),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _visitTypes.map((type) {
                          final isSelected = _selectedVisitType == type;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedVisitType = type;
                                if (type == "Tele-Consult") {
                                  _isTeleConsultation = true;
                                } else {
                                  _isTeleConsultation = false;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                ),
                              ),
                              child: Text(
                                (isPatient && type == "Tele-Consult") ? "Video consult" : type,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      _buildInputLabel(isPatient ? "Reason for visit *" : "Reason / Chief Complaint *", isDark, isTab),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reasonController,
                        maxLines: 2,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(250),
                        ],
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (val) {
                          if (_reasonError != null) {
                            setState(() => _reasonError = null);
                          }
                        },
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 15 : 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _inputDecoration(
                          hintText: isPatient ? "Describe your symptoms or reason for the visit" : "Enter primary complaint or purpose of visit...",
                          prefixIcon: Icons.edit_note_rounded,
                          isDark: isDark,
                          errorText: _reasonError,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Teleconsultation row (patients use the "Video consult" visit type)
                      if (!isPatient)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Teleconsultation (Zoom Video)",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  "Automatically generate video link & send WhatsApp invite",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isTeleConsultation,
                            activeTrackColor: primaryColor,
                            activeThumbColor: Colors.white,
                            onChanged: (val) {
                              setState(() {
                                _isTeleConsultation = val;
                                if (val && _selectedVisitType != "Tele-Consult") {
                                  _selectedVisitType = "Tele-Consult";
                                } else if (!val && _selectedVisitType == "Tele-Consult") {
                                  _selectedVisitType = "Consultation";
                                }
                              });
                            },
                          ),
                        ],
                      ),

                      // Teleconsultation payment setup removed per user request

                      if (!isPatient) ...[
                        const SizedBox(height: 18),
                        Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        const SizedBox(height: 18),

                        // 4. Treatment Plans & Procedures (Provider / Doctor only)
                        _buildSectionHeader(4, "Treatment Plans & Procedures", isDark),
                        const SizedBox(height: 12),
                        _buildTreatmentPlansSection(isDark, isTab),
                      ],

                      const SizedBox(height: 18),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 18),

                      // Billing & Payment
                      _buildSectionHeader(isPatient ? 4 : 5, isPatient ? "Payment" : "Billing & Payment", isDark),
                      const SizedBox(height: 14),

                      if (isPatient)
                        _buildPatientPaymentSummary(isDark)
                      else ...[
                      // Consultation fee row
                      Builder(
                        builder: (context) {
                          final isPatient = _isPatientUser;
                          if (isPatient) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Consultation Fee",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      "Doctor Fee: ₹${_consultationFee.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "₹${_consultationFee.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Include Consultation Fee",
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    _includeConsultationFee ? "Doctor Fee: ₹${_consultationFee.toStringAsFixed(0)}" : "Fee excluded / waived",
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    "₹${_consultationFee.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _includeConsultationFee
                                          ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                          : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                      decoration: !_includeConsultationFee ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch.adaptive(
                                    value: _includeConsultationFee,
                                    activeTrackColor: primaryColor,
                                    activeThumbColor: Colors.white,
                                    onChanged: (val) {
                                      setState(() {
                                        _includeConsultationFee = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      if (!_isPatientUser) ...[
                        const SizedBox(height: 12),
                        _buildInputLabel("Discount Amount (₹)", isDark, isTab),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onChanged: (val) => setState(() {}),
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          decoration: _inputDecoration(
                            hintText: "Enter discount (e.g. 100)",
                            prefixIcon: Icons.local_offer_outlined,
                            isDark: isDark,
                            suffixIcon: _discountController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () => setState(() => _discountController.clear()),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Quick Discount Chips
                        Wrap(
                          spacing: 8,
                          children: [50, 100, 200, 500].map((amt) {
                            final isCurrent = _discountController.text == amt.toString();
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isCurrent) {
                                    _discountController.clear();
                                  } else {
                                    _discountController.text = amt.toString();
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? primaryColor.withValues(alpha: 0.12)
                                      : (isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCurrent
                                        ? primaryColor
                                        : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Text(
                                  "₹$amt Off",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isCurrent
                                        ? primaryColor
                                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Compact Bill Summary
                      Builder(
                        builder: (context) {
                          final isPatient = _isPatientUser;
                          final double discount = !isPatient ? (double.tryParse(_discountController.text.trim()) ?? 0.0) : 0.0;
                          final double consultationFeeAmt = (isPatient || _includeConsultationFee) ? _consultationFee : 0.0;

                          double treatmentTotal = 0;
                          for (final planId in _selectedTreatmentPlanIds) {
                            final plan = _allTreatmentPlans.firstWhere(
                              (p) => p.id == planId,
                              orElse: () => const TreatmentPlanOption(id: '', name: '', description: '', amount: 0, status: ''),
                            );
                            treatmentTotal += plan.amount;
                          }

                          final double grossTotal = consultationFeeAmt + treatmentTotal;
                          final double netTotal = (grossTotal - discount) > 0 ? (grossTotal - discount) : 0.0;

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Consultation Fee",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11.5,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      _includeConsultationFee ? "₹${_consultationFee.toStringAsFixed(0)}" : "₹0",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                if (treatmentTotal > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Procedures (${_selectedTreatmentPlanIds.length})",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        "+ ₹${treatmentTotal.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (discount > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Discount",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                      Text(
                                        "- ₹${discount.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Estimated Total",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      "₹${netTotal.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Record Sharing Consent Card (Default: Checked / 7-Day Access)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _shareRecords
                        ? primaryColor.withValues(alpha: isDark ? 0.12 : 0.06)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _shareRecords
                          ? primaryColor.withValues(alpha: 0.35)
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      width: 1.2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _shareRecords = !_shareRecords;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.scale(
                          scale: 1.05,
                          child: Checkbox(
                            value: _shareRecords,
                            activeColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                _shareRecords = val ?? true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    size: 16,
                                    color: _shareRecords ? primaryColor : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Share Medical Records (7 Days Access)",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab ? 13.5 : 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Allow \${_selectedDoctorMap?['name'] ?? _selectedDoctor ?? 'the doctor'} to access your medical history and records for 7 days during consultation. You can revoke access anytime in Approvals.",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 12 : 11,
                                  height: 1.35,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 7. Submit Button
                Builder(
                  builder: (context) {
                    final bool isSubmitting = state is BookAppointmentLoadingState;
                    return Column(
                      children: [
                        InkWell(
                          onTap: isSubmitting ? null : () => _validateAndSubmit(context),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              color: isSubmitting ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: isSubmitting ? 0.15 : 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isSubmitting
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "Booking Appointment...",
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isTeleConsultation ? Icons.lock_outline_rounded : Icons.check_circle_outline_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isTeleConsultation
                                              ? (_consultationFee > 0
                                                  ? "Pay ₹${_consultationFee.toStringAsFixed(0)} & Confirm"
                                                  : "Confirm Tele-Consult")
                                              : (isPatient ? "Confirm booking" : "Confirm & Book Appointment"),
                                          style: const TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Discard Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: TextButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(context),
                            child: Text(
                              "Discard",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Form Section Header ──
  Widget _buildSectionHeader(int number, String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "$number",
              style: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // ── Doctor Info Header (Clean Row or Liked/Linked Hospital & Doctor Selectors for Patient) ──
  // ───────────────────────────────────────────────────────────────────────
  // PATIENT BOOKING LAYOUT
  // Follows the pattern of consumer booking apps: doctor on top, visit type,
  // a day strip, open times grouped by part of day, who it is for, reason,
  // and a sticky bar with the chosen time, fee and the Book button.
  // ───────────────────────────────────────────────────────────────────────

  static const int _dateStripDays = 60;
  static const double _dateItemWidth = 62;
  static const double _dateItemGap = 8;
  final ScrollController _dateStripCtrl = ScrollController();
  DateTime? _dateStripScrolledTo;

  static const List<String> _patientReasonChips = [
    "Fever",
    "Cold & cough",
    "Follow-up",
    "General check-up",
    "Body pain",
    "Skin problem",
  ];

  Color _pText(bool isDark) => isDark ? Colors.white : const Color(0xFF0F172A);
  Color _pMuted(bool isDark) => isDark ? Colors.white60 : const Color(0xFF64748B);
  Color _pCard(bool isDark) => isDark ? const Color(0xFF232323) : Colors.white;
  Color _pLine(bool isDark) => isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE6EAF0);

  Widget _pSectionTitle(String title, bool isDark, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: _pText(isDark)),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildPatientBookingScaffold(BuildContext context, AppointmentState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);
    final bool isSubmitting = state is BookAppointmentLoadingState;
    final double hPad = isTab ? 32 : 16;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _pCard(isDark),
        foregroundColor: _pText(isDark),
        centerTitle: true,
        title: Text(
          "Book appointment",
          style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700, fontSize: isTab ? 19 : 17),
        ),
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsBold.caretLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingInitial
          ? _buildFullAppointmentShimmer(isDark, isTab)
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 24),
              children: [
                _buildDoctorHeader(isDark, isTab),
                if (_selectedDoctorMap != null) ...[
                  const SizedBox(height: 22),
                  _pSectionTitle("Consultation type", isDark),
                  _buildVisitModeToggle(isDark),
                  if (!_isTeleConsultation) ...[
                    const SizedBox(height: 10),
                    _buildVisitPurposeChips(isDark),
                  ],
                  const SizedBox(height: 22),
                  _pSectionTitle(
                    "Select date",
                    isDark,
                    trailing: TextButton.icon(
                      onPressed: () => _showDatePicker(context, _selectedDate, isDark),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const PhosphorIcon(PhosphorIconsBold.calendarBlank, size: 15, color: primaryColor),
                      label: Text(
                        DateFormat('MMMM yyyy').format(_selectedDate),
                        style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: primaryColor),
                      ),
                    ),
                  ),
                  _buildDateStrip(isDark),
                  const SizedBox(height: 22),
                  _pSectionTitle(
                    "Available time",
                    isDark,
                    trailing: _isLoadingSlots
                        ? null
                        : Text(
                            () {
                              final n = _allDoctorSlots.where((s) => s.isSelectableForDate(_selectedDate)).length;
                              return n == 1 ? "1 slot" : "$n slots";
                            }(),
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: _pMuted(isDark)),
                          ),
                  ),
                  if (_isLoadingSlots) _buildSlotsShimmer(isDark, isTab) else _buildPatientSlots(isDark, isTab),
                  if (_slotError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 2),
                      child: Text(
                        _slotError!,
                        style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                      ),
                    ),
                  const SizedBox(height: 22),
                  _pSectionTitle("Booking for", isDark),
                  _buildBookingForCard(isDark, isTab),
                  const SizedBox(height: 22),
                  _pSectionTitle("Reason for visit", isDark),
                  _buildPatientReasonField(isDark),
                  const SizedBox(height: 22),
                  _pSectionTitle("Payment", isDark),
                  _buildPatientPaymentSummary(isDark),
                ],
              ],
            ),
      bottomNavigationBar: (_isLoadingInitial || _selectedDoctorMap == null)
          ? null
          : _buildPatientBookingBar(context, isDark, isSubmitting),
    );
  }

  Widget _buildVisitModeToggle(bool isDark) {
    final String feeText = _consultationFee > 0 ? "₹${_consultationFee.toStringAsFixed(0)}" : "Free";
    Widget option({required bool selected, required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
      return Expanded(
        child: Material(
          color: selected ? primaryColor.withValues(alpha: isDark ? 0.18 : 0.06) : _pCard(isDark),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? primaryColor : _pLine(isDark), width: selected ? 1.6 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? primaryColor : primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: PhosphorIcon(icon, size: 18, color: selected ? Colors.white : primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700, color: _pText(isDark))),
                        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w500, color: _pMuted(isDark))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(
          selected: !_isTeleConsultation,
          icon: PhosphorIconsBold.hospital,
          title: "Clinic visit",
          subtitle: feeText,
          onTap: () => setState(() {
            _isTeleConsultation = false;
            if (_selectedVisitType == "Tele-Consult") _selectedVisitType = "Consultation";
          }),
        ),
        const SizedBox(width: 10),
        option(
          selected: _isTeleConsultation,
          icon: PhosphorIconsBold.videoCamera,
          title: "Video consult",
          subtitle: feeText,
          onTap: () => setState(() {
            _isTeleConsultation = true;
            _selectedVisitType = "Tele-Consult";
          }),
        ),
      ],
    );
  }

  Widget _buildVisitPurposeChips(bool isDark) {
    const purposes = {"Consultation": "New consultation", "Follow-up": "Follow-up", "Check-up": "Check-up"};
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: purposes.entries.map((e) {
        final selected = _selectedVisitType == e.key;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => setState(() => _selectedVisitType = e.key),
          labelStyle: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primaryColor : _pMuted(isDark),
          ),
          backgroundColor: _pCard(isDark),
          selectedColor: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
          side: BorderSide(color: selected ? primaryColor : _pLine(isDark)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildDateStrip(bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedIndex = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).difference(today).inDays;

    // Keep the chosen day in view, e.g. after picking from the calendar.
    if (_dateStripScrolledTo == null || !_sameDay(_dateStripScrolledTo!, _selectedDate)) {
      _dateStripScrolledTo = _selectedDate;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_dateStripCtrl.hasClients || selectedIndex < 0) return;
        final target = (selectedIndex * (_dateItemWidth + _dateItemGap) - 24)
            .clamp(0.0, _dateStripCtrl.position.maxScrollExtent)
            .toDouble();
        _dateStripCtrl.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });
    }

    return SizedBox(
      height: 78,
      child: ListView.separated(
        controller: _dateStripCtrl,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dateStripDays,
        separatorBuilder: (_, _) => const SizedBox(width: _dateItemGap),
        itemBuilder: (context, i) {
          final day = today.add(Duration(days: i));
          final selected = _sameDay(day, _selectedDate);
          final top = i == 0 ? "Today" : (i == 1 ? "Tmrw" : DateFormat('EEE').format(day));
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (selected) return;
              setState(() {
                _selectedDate = day;
                _dateChosenByUser = true;
                _slotError = null;
              });
              _fetchDoctorSlots(day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _dateItemWidth,
              decoration: BoxDecoration(
                color: selected ? primaryColor : _pCard(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? primaryColor : _pLine(isDark)),
                boxShadow: selected
                    ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    top,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white70 : _pMuted(isDark)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 19, fontWeight: FontWeight.w800, color: selected ? Colors.white : _pText(isDark), height: 1.15),
                  ),
                  Text(
                    DateFormat('MMM').format(day),
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, fontWeight: FontWeight.w500, color: selected ? Colors.white70 : _pMuted(isDark)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientSlots(bool isDark, bool isTab) {
    final open = _allDoctorSlots.where((s) => s.isSelectableForDate(_selectedDate)).toList();
    if (open.isEmpty) return _buildNoSlotsNotice(isDark);

    final groups = <({String label, IconData icon, Color color, List<DoctorSlotItem> slots})>[
      (label: "Morning", icon: PhosphorIconsFill.sunHorizon, color: const Color(0xFFF59E0B), slots: open.where((s) => s.startHour < 12).toList()),
      (label: "Afternoon", icon: PhosphorIconsFill.sun, color: const Color(0xFFF97316), slots: open.where((s) => s.startHour >= 12 && s.startHour < 17).toList()),
      (label: "Evening", icon: PhosphorIconsFill.moonStars, color: const Color(0xFF6366F1), slots: open.where((s) => s.startHour >= 17).toList()),
    ].where((g) => g.slots.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: _pCard(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pLine(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in groups) ...[
            Row(
              children: [
                PhosphorIcon(g.icon, size: 16, color: g.color),
                const SizedBox(width: 6),
                Text(g.label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700, color: _pText(isDark))),
                const SizedBox(width: 6),
                Text("· ${g.slots.length} ${g.slots.length == 1 ? 'slot' : 'slots'}", style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: _pMuted(isDark))),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: isTab ? 5 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isTab ? 2.8 : 2.5,
              children: [for (final slot in g.slots) _buildPatientSlotChip(slot, isDark)],
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientSlotChip(DoctorSlotItem slot, bool isDark) {
    final selected = _selectedSlot == slot.label;
    final parsed = DoctorSlotItem.parseSlotDateTime(_selectedDate, slot.startTime);
    final label = parsed != null ? DateFormat('h:mm a').format(parsed) : slot.startTime;
    return Material(
      color: selected ? primaryColor : (isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC)),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _selectedSlot = slot.label;
          _slotError = null;
        }),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? primaryColor : _pLine(isDark)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? Colors.white : _pText(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingForCard(bool isDark, bool isTab) {
    final patient = _selectedPatient;
    final showList = patient == null || _isChangingPatient;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pCard(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pLine(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (patient != null && !_isChangingPatient)
            Row(
              children: [
                EntityLogo(imageUrl: null, name: patient.name, size: 44, radius: 22, isLogo: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 14.5, fontWeight: FontWeight.w700, color: _pText(isDark)),
                      ),
                      Text(
                        [
                          (patient.isPrimary || patient.relation.toLowerCase() == 'self') ? "You" : patient.relation,
                          if (patient.gender.isNotEmpty) patient.gender,
                          if (patient.displayAge.isNotEmpty && patient.displayAge != '0 Yrs') patient.displayAge.replaceAll('Yrs', 'yrs'),
                        ].join(' · '),
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: _pMuted(isDark)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _isChangingPatient = true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text("Change", style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          if (showList) ...[
            _buildMatchingAccountsList(isDark, isTab),
            if (patient != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _isChangingPatient = false),
                  child: const Text("Cancel", style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600, color: primaryColor)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientReasonField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _reasonController,
          maxLines: 2,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [LengthLimitingTextInputFormatter(250)],
          onChanged: (_) {
            if (_reasonError != null) setState(() => _reasonError = null);
          },
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: _pText(isDark)),
          decoration: InputDecoration(
            hintText: "Describe your symptoms or reason for the visit",
            hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            filled: true,
            fillColor: _pCard(isDark),
            errorText: _reasonError,
            contentPadding: const EdgeInsets.all(14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _pLine(isDark))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryColor, width: 1.4)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDC2626))),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4)),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _patientReasonChips.map((r) {
            final selected = _reasonController.text.trim() == r;
            return ActionChip(
              label: Text(r),
              onPressed: () => setState(() {
                _reasonController.text = r;
                _reasonError = null;
              }),
              labelStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w600, color: selected ? primaryColor : _pMuted(isDark)),
              backgroundColor: selected ? primaryColor.withValues(alpha: 0.08) : _pCard(isDark),
              side: BorderSide(color: selected ? primaryColor : _pLine(isDark)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPatientBookingBar(BuildContext context, bool isDark, bool isSubmitting) {
    final bool hasSlot = _selectedSlot.trim().isNotEmpty &&
        _allDoctorSlots.any((s) => s.label == _selectedSlot && s.isSelectableForDate(_selectedDate));
    final double fee = _consultationFee;
    final String when = hasSlot
        ? "${DateFormat('EEE, d MMM').format(_selectedDate)} · ${_slotLabel12h(_selectedSlot)}"
        : "Pick a time";
    final String feeLine = fee <= 0
        ? "Free consultation"
        : "₹${fee.toStringAsFixed(0)} · ${_isTeleConsultation ? 'Pay online' : 'Pay at clinic'}";
    final String cta = (_isTeleConsultation && fee > 0) ? "Pay & book" : "Book now";

    return Container(
      decoration: BoxDecoration(
        color: _pCard(isDark),
        border: Border(top: BorderSide(color: _pLine(isDark))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      when,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w700, color: hasSlot ? _pText(isDark) : _pMuted(isDark)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feeLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w500, color: fee <= 0 ? const Color(0xFF059669) : _pMuted(isDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (isSubmitting || !hasSlot) ? null : () => _validateAndSubmit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.35),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    // The app theme makes buttons full width; this one sits in a row.
                    minimumSize: const Size(120, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                      : Text(cta, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown to patients when the chosen date has no open slots.
  Widget _buildNoSlotsNotice(bool isDark) {
    final bool isToday = _sameDay(_selectedDate, DateTime.now());
    final DateTime next = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1);
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pCard(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pLine(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PhosphorIcon(PhosphorIconsDuotone.calendarX, size: 22, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isToday ? "No more slots today" : "No open slots on ${DateFormat('EEE, d MMM').format(_selectedDate)}",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Try another day, or pick a date from the calendar above.",
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedDate = next;
                _dateChosenByUser = true;
              });
              _fetchDoctorSlots(next);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(0, 40),
            ),
            icon: const PhosphorIcon(PhosphorIconsBold.arrowRight, size: 14, color: primaryColor),
            label: Text(
              "Check ${DateFormat('EEE, d MMM').format(next)}",
              style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// What a patient pays and where. One line instead of a staff bill.
  Widget _buildPatientPaymentSummary(bool isDark) {
    final double fee = _consultationFee;
    final bool online = _isTeleConsultation;
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    final String note = fee <= 0
        ? "No payment needed for this visit."
        : (online ? "Pay online to confirm your video consultation." : "Pay at the clinic when you arrive.");
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pCard(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pLine(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Consultation fee",
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),
              Text(
                fee > 0 ? "₹${fee.toStringAsFixed(0)}" : "Free",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: fee > 0 ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              PhosphorIcon(online ? PhosphorIconsBold.creditCard : PhosphorIconsBold.storefront, size: 15, color: muted),
              const SizedBox(width: 8),
              Expanded(child: Text(note, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted))),
            ],
          ),
        ],
      ),
    );
  }

  /// The doctor and hospital a patient is booking with. Registration and
  /// personal contact numbers are not shown to patients.
  Widget _buildPatientDoctorCard(Map<String, dynamic> doc, bool isDark, bool isTab) {
    final docName = (doc['name'] ?? doc['displayName'] ?? 'Doctor').toString().trim();
    final specialty = (doc['specialty'] ?? doc['Specialty'] ?? '').toString().trim();
    final qualification = (doc['qualification'] ?? doc['Qualification'] ?? '').toString().trim();
    final imagePath = (doc['imagePath'] ?? doc['ImagePath'] ?? doc['profileImage'] ?? '').toString().trim();
    final hosp = _selectedHospital;
    final hospitalName = (hosp?['name'] ?? doc['hospitalName'] ?? '').toString().trim();
    final address = (hosp?['address'] ?? '').toString().trim();
    final hospitalPlace = address.isNotEmpty ? address : (hosp?['city'] ?? '').toString().trim();
    final hospitalLogo = (hosp?['logo'] ?? hosp?['logoUrl'] ?? hosp?['imageUrl'])?.toString();
    final bool canChange = _filteredDoctors.length > 1 || _hospitals.length > 1;
    final strong = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTab ? 16 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE6EAF0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EntityLogo(imageUrl: imagePath, name: docName, size: isTab ? 60 : 56, radius: 16, isLogo: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The badge follows the last word, even when the name wraps.
                    Text.rich(
                      TextSpan(
                        text: docName,
                        children: const [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: PhosphorIcon(PhosphorIconsFill.sealCheck, size: 15, color: Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 16 : 15, fontWeight: FontWeight.w700, color: strong, height: 1.25),
                    ),
                    if (specialty.isNotEmpty)
                      Text(
                        specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                      ),
                    if (qualification.isNotEmpty)
                      Text(
                        qualification,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted),
                      ),
                  ],
                ),
              ),
              if (canChange)
                TextButton(
                  onPressed: () => setState(() => _showDoctorPicker = true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Change",
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
                  ),
                ),
            ],
          ),
          if (hospitalName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Row(
              children: [
                EntityLogo(imageUrl: hospitalLogo, name: hospitalName, size: 34, radius: 9),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospitalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: strong),
                      ),
                      if (hospitalPlace.isNotEmpty)
                        Text(
                          hospitalPlace,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorHeader(bool isDark, bool isTab) {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final bool isPatient = currentUser?.data?.navigationId == "1" ||
        (currentUser?.data?.latestUserRole ?? '').toLowerCase().contains("patient") ||
        (currentUser?.data?.latestUserRole ?? '').toLowerCase() == "user";

    if (isPatient) {
      if (_hospitals.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "No Linked Hospitals",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 16 : 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Only liked and linked hospitals are allowed for patient appointment bookings. Connect with your doctor or hospital by scanning their QR code.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13 : 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScanDoctorQrSheet.show(
                    context,
                    onDoctorLinked: (newDoc) {
                      _initPatientHospitalsAndDoctors();
                    },
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                label: const Text(
                  "Scan Doctor / Clinic QR",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (_selectedDoctorMap != null && !_showDoctorPicker && !_isLoadingDoctors) {
        return _buildPatientDoctorCard(_selectedDoctorMap!, isDark, isTab);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel("Hospital / Clinic", isDark, isTab),
          const SizedBox(height: 6),
          () {
            final seenHospIds = <String>{};
            final List<Map<String, dynamic>> distinctHospitals = [];
            for (final h in _hospitals) {
              final hId = (h['id'] ?? h['hospitalId'])?.toString().trim();
              if (hId != null && hId.isNotEmpty && seenHospIds.add(hId)) {
                distinctHospitals.add(h);
              }
            }

            final currentHospId = (_selectedHospital?['id'] ?? _selectedHospital?['hospitalId'])?.toString().trim();
            final selectedHospId = distinctHospitals.any((h) => (h['id'] ?? h['hospitalId'])?.toString().trim() == currentHospId)
                ? currentHospId
                : (distinctHospitals.isNotEmpty ? (distinctHospitals.first['id'] ?? distinctHospitals.first['hospitalId'])?.toString().trim() : null);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedHospId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                  dropdownColor: isDark ? const Color(0xFF232323) : Colors.white,
                  items: distinctHospitals.map((h) {
                    final hId = (h['id'] ?? h['hospitalId'])?.toString().trim() ?? '';
                    return DropdownMenuItem<String>(
                      value: hId,
                      child: Row(
                        children: [
                          EntityLogo(
                            imageUrl: (h['logo'] ?? h['logoUrl'] ?? h['imageUrl'])?.toString(),
                            name: (h['name'] ?? 'Hospital').toString(),
                            size: 26,
                            radius: 7,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              h['name'] ?? 'Hospital',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (valId) async {
                    if (valId != null) {
                      final h = distinctHospitals.firstWhere(
                        (item) => (item['id'] ?? item['hospitalId'])?.toString().trim() == valId,
                        orElse: () => distinctHospitals.first,
                      );
                      setState(() {
                        _selectedHospital = h;
                        _selectedTreatmentPlanIds.clear();
                      });
                      await _filterDoctorsForHospital(h['id']);
                    }
                  },
                ),
              ),
            );
          }(),
          const SizedBox(height: 14),
          _buildInputLabel("Doctor", isDark, isTab),
          const SizedBox(height: 6),
          if (_isLoadingDoctors) ...[
            _buildDoctorDropdownShimmer(isDark),
          ] else if (_filteredDoctors.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "No connected doctors for this hospital. Scan doctor's QR code to link.",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScanDoctorQrSheet.show(
                        context,
                        onDoctorLinked: (newDoc) {
                          _initPatientHospitalsAndDoctors();
                        },
                      );
                    },
                    child: const Text(
                      "Scan QR",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            () {
              final seenDocIds = <String>{};
              final List<Map<String, dynamic>> distinctDoctors = [];
              for (final doc in _filteredDoctors) {
                final dId = (doc['doctorId'] ?? doc['id'] ?? doc['userId'])?.toString().trim();
                if (dId != null && dId.isNotEmpty && seenDocIds.add(dId)) {
                  distinctDoctors.add(doc);
                }
              }

              final currentDocId = (_selectedDoctorMap?['doctorId'] ?? _selectedDoctorMap?['id'] ?? _selectedDoctorMap?['userId'])?.toString().trim();
              final selectedDocId = distinctDoctors.any((d) => (d['doctorId'] ?? d['id'] ?? d['userId'])?.toString().trim() == currentDocId)
                  ? currentDocId
                  : (distinctDoctors.isNotEmpty ? (distinctDoctors.first['doctorId'] ?? distinctDoctors.first['id'] ?? distinctDoctors.first['userId'])?.toString().trim() : null);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDocId,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                    dropdownColor: isDark ? const Color(0xFF232323) : Colors.white,
                    items: distinctDoctors.map((doc) {
                      final docId = (doc['doctorId'] ?? doc['id'] ?? doc['userId'])?.toString().trim() ?? '';
                      return DropdownMenuItem<String>(
                        value: docId,
                        child: Row(
                          children: [
                            EntityLogo(
                              imageUrl: (doc['imagePath'] ?? doc['profileImage'])?.toString(),
                              name: (doc['name'] ?? 'Doctor').toString(),
                              size: 26,
                              radius: 13,
                              isLogo: false,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "${doc['name']} • ${doc['specialty'] ?? 'Specialist'} (₹${doc['consultationFee'] ?? 0})",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (valId) {
                      if (valId != null) {
                        final doc = distinctDoctors.firstWhere(
                          (d) => (d['doctorId'] ?? d['id'] ?? d['userId'])?.toString().trim() == valId,
                          orElse: () => distinctDoctors.first,
                        );
                        setState(() {
                          _selectedDoctorMap = doc;
                          _showDoctorPicker = false;
                          _selectedDoctor = doc['name'] ?? 'Doctor';
                          _consultationFee = (double.tryParse(doc['consultationFee']?.toString() ?? '') ?? 0.0);
                        });
                        _fetchDoctorSlots(_selectedDate);
                      }
                    },
                  ),
                ),
              );
            }(),
            if (_selectedDoctorMap != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _showDoctorPicker = false),
                  child: const Text(
                    "Done",
                    style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700, color: primaryColor),
                  ),
                ),
              ),
          ],
        ],
      );
    }

    final docMap = _selectedDoctorMap ?? widget.initialDoctor;
    if (docMap != null) {
      return _buildDoctorInfoCard(docMap, isDark, isTab);
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: primaryColor.withValues(alpha: 0.12),
          child: const Icon(Icons.person_rounded, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedDoctor,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                "Consultation Appointment",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Doctor Info Card (Displays all available doctor details from database) ──
  Widget _buildDoctorInfoCard(Map<String, dynamic> doc, bool isDark, bool isTab) {
    final docName = (doc['name'] ?? doc['displayName'] ?? 'Doctor').toString().trim();
    final specialty = (doc['specialty'] ?? doc['Specialty'] ?? 'General Physician').toString().trim();
    final subSpecialty = (doc['subSpecialty'] ?? doc['SubSpecialty'] ?? '').toString().trim();
    final regNo = (doc['registrationNumber'] ?? doc['RegistrationNumber'] ?? '').toString().trim();
    final bio = (doc['bio'] ?? doc['Bio'] ?? '').toString().trim();
    final hospitalName = (doc['hospitalName'] ?? doc['Hospital']?['Name'] ?? _selectedHospital?['name'] ?? '').toString().trim();
    final email = (doc['email'] ?? doc['Email'] ?? '').toString().trim();
    final phoneNumber = (doc['phoneNumber'] ?? doc['PhoneNumber'] ?? '').toString().trim();
    final imagePath = (doc['imagePath'] ?? doc['ImagePath'] ?? doc['profileImage'] ?? '').toString().trim();
    final rawFee = doc['consultationFee'] ?? doc['ConsultationFee'];
    final fee = rawFee != null ? double.tryParse(rawFee.toString()) : null;

    final initial = docName.replaceFirst(RegExp(r'^(Dr\.\s*|Dr\s+|Doctor\s*)', caseSensitive: false), '').trim().isNotEmpty
        ? docName.replaceFirst(RegExp(r'^(Dr\.\s*|Dr\s+|Doctor\s*)', caseSensitive: false), '').trim()[0].toUpperCase()
        : 'D';
    final bool hasImage = imagePath.isNotEmpty && (imagePath.startsWith('http://') || imagePath.startsWith('https://'));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTab ? 16 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Doctor Avatar + Name + Specialization & Hospital ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: isTab ? 54 : 48,
                    height: isTab ? 54 : 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasImage
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: primaryColor.withValues(alpha: 0.12),
                                alignment: Alignment.center,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: primaryColor.withValues(alpha: 0.12),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF121212) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            docName,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 15 : 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF2563EB)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hospitalName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital_rounded,
                            size: 12,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hospitalName,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Row 2: Sub-Specialty / Reg No in Plain Style (MBBS, experience & administrator removed per user request) ──
          if ((subSpecialty.isNotEmpty && subSpecialty != specialty) || regNo.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (subSpecialty.isNotEmpty && subSpecialty != specialty)
                  _buildDoctorDetailChip(
                    icon: Icons.hub_rounded,
                    label: subSpecialty,
                    isDark: isDark,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                if (regNo.isNotEmpty)
                  _buildDoctorDetailChip(
                    icon: Icons.badge_rounded,
                    label: "Reg: $regNo",
                    isDark: isDark,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
              ],
            ),
          ],

          // ── Row 3: Doctor Bio / About (if present) ──
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232323) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Row 4: Consultation Fee & Contact Info ──
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      size: 13,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "CONSULTATION FEE",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        fee == null || fee == 0 ? "Free Consultation" : "₹${fee.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: fee == null || fee == 0
                              ? const Color(0xFF059669)
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (phoneNumber.isNotEmpty || email.isNotEmpty)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (phoneNumber.isNotEmpty) ...[
                        Icon(Icons.phone_in_talk_rounded, size: 12, color: primaryColor),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            phoneNumber,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else if (email.isNotEmpty) ...[
                        Icon(Icons.mail_outline_rounded, size: 12, color: primaryColor),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            email,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorDetailChip({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grouped Slots View ──
  Widget _buildGroupedSlotsView(bool isDark, bool isTab) {
    final bool patientView = _isPatientUser;
    final List<DoctorSlotItem> source =
        patientView ? _allDoctorSlots.where((s) => !s.isPastForDate(_selectedDate)).toList() : _allDoctorSlots;
    if (patientView && !source.any((s) => s.isSelectableForDate(_selectedDate))) {
      return _buildNoSlotsNotice(isDark);
    }
    final morningSlots = source.where((s) => s.startHour < 12).toList();
    final afternoonSlots = source.where((s) => s.startHour >= 12 && s.startHour < 17).toList();
    final eveningSlots = source.where((s) => s.startHour >= 17).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morningSlots.isNotEmpty)
          _buildSlotTimePeriodSection(
            isDark: isDark,
            isTab: isTab,
            label: "Morning",
            count: morningSlots.where((s) => s.isSelectableForDate(_selectedDate)).length,
            slots: morningSlots,
          ),
        if (morningSlots.isNotEmpty && (afternoonSlots.isNotEmpty || eveningSlots.isNotEmpty))
          const SizedBox(height: 12),
        if (afternoonSlots.isNotEmpty)
          _buildSlotTimePeriodSection(
            isDark: isDark,
            isTab: isTab,
            label: "Afternoon",
            count: afternoonSlots.where((s) => s.isSelectableForDate(_selectedDate)).length,
            slots: afternoonSlots,
          ),
        if (afternoonSlots.isNotEmpty && eveningSlots.isNotEmpty)
          const SizedBox(height: 12),
        if (eveningSlots.isNotEmpty)
          _buildSlotTimePeriodSection(
            isDark: isDark,
            isTab: isTab,
            label: "Evening",
            count: eveningSlots.where((s) => s.isSelectableForDate(_selectedDate)).length,
            slots: eveningSlots,
          ),
      ],
    );
  }

  Widget _buildSlotTimePeriodSection({
    required bool isDark,
    required bool isTab,
    required String label,
    required int count,
    required List<DoctorSlotItem> slots,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            Text(
              count > 0 ? "$count open" : "Full",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: count > 0 ? const Color(0xFF059669) : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTab ? 4 : 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: isTab ? 2.8 : 2.2,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            return _buildSlotCard(slots[index], isDark);
          },
        ),
      ],
    );
  }

  Widget _buildSlotCard(DoctorSlotItem slot, bool isDark) {
    final bool isSelectable = slot.isSelectableForDate(_selectedDate);
    final bool isPast = slot.isPastForDate(_selectedDate);
    final bool isSelected = _selectedSlot == slot.label && isSelectable;
    String displayTime = slot.startTime.length >= 5 ? slot.startTime.substring(0, 5) : slot.startTime;
    if (_isPatientUser) {
      final parsed = DoctorSlotItem.parseSlotDateTime(_selectedDate, slot.startTime);
      if (parsed != null) displayTime = DateFormat('h:mm a').format(parsed);
    }

    if (!isSelectable) {
      final bool isBooked = slot.isBooked;
      final String statusLabel = isPast
          ? "Passed"
          : isBooked
              ? "Booked"
              : "Blocked";

      return InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPast
                    ? "This slot has already passed."
                    : (isBooked
                        ? "This slot is already booked. Please select an available slot."
                        : "This slot is currently blocked by the doctor."),
                style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2633) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBooked
                  ? (isDark ? Colors.redAccent.withValues(alpha: 0.25) : Colors.red.withValues(alpha: 0.2))
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayTime,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isBooked) ...[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 9.5,
                        color: isDark ? Colors.redAccent.withValues(alpha: 0.7) : Colors.red.shade400,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: isBooked
                            ? (isDark ? Colors.redAccent.withValues(alpha: 0.8) : Colors.red.shade500)
                            : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSlot = slot.label;
          if (_slotError != null) _slotError = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Center(
          child: Text(
            displayTime,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text, bool isDark, bool isTab) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: isTab ? 13 : 12,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : const Color(0xFF334155),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
    String? errorText,
    String? prefixText,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 12.5,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
      prefixIcon: prefix ??
          Icon(
            prefixIcon,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
            size: 18,
          ),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
      ),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorStyle: const TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 11,
        color: Color(0xFFDC2626),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null
              ? const Color(0xFFDC2626)
              : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null ? const Color(0xFFDC2626) : primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.5,
        ),
      ),
    );
  }

  void _showDatePicker(
    BuildContext context,
    DateTime initialDate,
    bool isDark,
  ) {
    DateTime tempSelectedDate = initialDate;

    showModalBottomSheet(
      isDismissible: true,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232323) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Select Consultation Date",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: displayHeight(context) / 3.8,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: isDark ? Brightness.dark : Brightness.light,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: initialDate,
                        minimumDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                        maximumDate: DateTime.now().add(const Duration(days: 90)),
                        itemExtent: 44,
                        onDateTimeChanged: (DateTime newDate) {
                          tempSelectedDate = newDate;
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDate = tempSelectedDate;
                          _dateChosenByUser = true;
                        });
                        _fetchDoctorSlots(_selectedDate);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Confirm Date",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 1. Patient Search Mode Tabs (Two Distinct Options) ──
  Widget _buildPatientSearchModeTabs(bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_patientSearchMode == PatientSearchMode.byPhone) return;
                setState(() {
                  _patientSearchMode = PatientSearchMode.byPhone;
                  _nameError = null;
                  _phoneError = null;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: _patientSearchMode == PatientSearchMode.byPhone
                      ? (isDark ? const Color(0xFF232323) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _patientSearchMode == PatientSearchMode.byPhone
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        size: 16,
                        color: _patientSearchMode == PatientSearchMode.byPhone
                            ? primaryColor
                            : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Search by Mobile",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          fontWeight: _patientSearchMode == PatientSearchMode.byPhone ? FontWeight.w700 : FontWeight.w500,
                          color: _patientSearchMode == PatientSearchMode.byPhone
                              ? (isDark ? Colors.white : const Color(0xFF1E293B))
                              : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                if (_patientSearchMode == PatientSearchMode.byName) return;
                setState(() {
                  _patientSearchMode = PatientSearchMode.byName;
                  _nameError = null;
                  _phoneError = null;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: _patientSearchMode == PatientSearchMode.byName
                      ? (isDark ? const Color(0xFF232323) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _patientSearchMode == PatientSearchMode.byName
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 16,
                        color: _patientSearchMode == PatientSearchMode.byName
                            ? primaryColor
                            : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Search by Name",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          fontWeight: _patientSearchMode == PatientSearchMode.byName ? FontWeight.w700 : FontWeight.w500,
                          color: _patientSearchMode == PatientSearchMode.byName
                              ? (isDark ? Colors.white : const Color(0xFF1E293B))
                              : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Selected Patient Summary Card ──
  Widget _buildSelectedPatientCard(bool isDark, bool isTab) {
    final patient = _selectedPatient!;
    final bool isIndependent = patient.isPrimary || patient.relation.toLowerCase() == 'self';
    const Color accentColor = Color(0xFF2563EB);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.15 : 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ Accent top strip (Solid) ─
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─ Header: avatar + name + badge + change button ─
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      patient.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab ? 16 : 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isIndependent ? Icons.person_rounded : Icons.people_alt_rounded,
                                          size: 11,
                                          color: accentColor,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isIndependent ? "Primary" : patient.relation,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (patient.gender.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        patient.gender,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isChangingPatient = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF232323) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz_rounded, size: 15, color: primaryColor),
                                SizedBox(width: 4),
                                Text(
                                  "Change",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // ─ Past visits badge ─
                    if (patient.pastAppointmentsCount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF232323) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_rounded, size: 13, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Text(
                              "${patient.pastAppointmentsCount} Prior Consultation(s)",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            if (patient.lastVisitDate != null && patient.lastVisitDate!.isNotEmpty) ...[
                              Text(
                                " · Last: ${patient.lastVisitDate}",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    // ─ Quick Book for Child / Family Option ─
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _showAddDependentDialog(context, isDark, initialRelation: "Child"),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.12 : 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.child_care_rounded, size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 6),
                            Text(
                              "+ Book for Child / Family Member instead",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3. Matching Accounts List (Independent & Dependent) ──
  Widget _buildMatchingAccountsList(bool isDark, bool isTab) {
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (cleanPhone.length < 10) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Enter 10-digit mobile number to find independent and dependent patient accounts.",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingAccounts) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                "Searching matching accounts...",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasSearchedPhone && _matchingAccountsList.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─ Accent strip (Solid) ─
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─ Header ─
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.person_add_rounded, color: primaryColor, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "New Patient Registration",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              "No accounts found",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ─ Patient Name ─
                  _buildInputLabel("Patient Name *", isDark, isTab),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _patientSearchController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    onChanged: (val) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 15 : 13.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: _inputDecoration(
                      hintText: "Enter full name (e.g. Rahul Sharma)",
                      prefixIcon: Icons.person_outline_rounded,
                      isDark: isDark,
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ─ Gender ─
                  _buildInputLabel("Gender", isDark, isTab),
                  const SizedBox(height: 6),
                  Row(
                    children: _genderOptions.map((gender) {
                      final isSelected = _selectedGender.toLowerCase() == gender.toLowerCase();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => setState(() => _selectedGender = gender),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? const Color(0xFF232323) : Colors.white),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  gender,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // ─ Divider + Add Family Member link ─
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _showAddDependentDialog(context, isDark),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF059669).withValues(alpha: 0.3),
                          ),
                          color: const Color(0xFF059669).withValues(alpha: isDark ? 0.08 : 0.04),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_add_rounded,
                              size: 15,
                              color: const Color(0xFF059669).withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Or Add as Family Member / Dependent",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF059669).withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isPatientUser ? "Your family profiles (${_matchingAccountsList.length})" : "Matching Accounts (${_matchingAccountsList.length})",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showAddDependentDialog(context, isDark),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.person_add_alt_1_rounded, size: 14, color: primaryColor),
                      SizedBox(width: 4),
                      Text(
                        "+ Add Dependent",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isPatientUser
                ? "Choose who the appointment is for, or add a family member below."
                : "Select an account to schedule for, or choose a relation below for their child / family member:",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 11.5,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _matchingAccountsList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final account = _matchingAccountsList[index];
              final bool isPrimaryItem = index == 0;
              final bool isSelected = _selectedPatient != null && _isSamePatient(_selectedPatient!, account);

              // Uniform blue theme and same icon for all matching accounts per user request
              const Color tileAccent = Color(0xFF2563EB);
              const IconData relationIcon = Icons.person_rounded;

              final String badgeText = isPrimaryItem ? "Primary" : account.relation;

              return InkWell(
                onTap: () => _selectPatientAccount(account),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tileAccent.withValues(alpha: isDark ? 0.2 : 0.08)
                        : (isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? tileAccent
                          : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ─ Role / Profile Avatar ─
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? tileAccent
                              : tileAccent.withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            relationIcon,
                            size: 19,
                            color: isSelected ? Colors.white : tileAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    isPrimaryItem ? "${account.name} (Primary)" : "${account.name} (${account.relation})",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tileAccent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: tileAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  account.gender.toLowerCase() == 'male'
                                      ? Icons.male_rounded
                                      : account.gender.toLowerCase() == 'female'
                                          ? Icons.female_rounded
                                          : Icons.person_rounded,
                                  size: 13,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    "${account.gender}${account.displayAge.isNotEmpty ? ' • ${account.displayAge}' : ''}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          key: ValueKey(isSelected),
                          size: 22,
                          color: isSelected ? tileAccent : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // ─ Quick Book for Family Member Section ─
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.family_restroom_rounded,
                      size: 15,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Book for Family Member",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildQuickRelationChip("Child", Icons.child_care_rounded, const Color(0xFF2563EB), isDark),
                    _buildQuickRelationChip("Spouse", Icons.favorite_rounded, const Color(0xFF2563EB), isDark),
                    _buildQuickRelationChip("Father", Icons.man_rounded, const Color(0xFF2563EB), isDark),
                    _buildQuickRelationChip("Mother", Icons.woman_rounded, const Color(0xFF2563EB), isDark),
                    _buildQuickRelationChip("Other", Icons.group_add_rounded, const Color(0xFF2563EB), isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRelationChip(
    String relation,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => _showAddDependentDialog(context, isDark, initialRelation: relation),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              "+ $relation",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Add Dependent / Family Member Dialog ──
  void _showAddDependentDialog(BuildContext context, bool isDark, {String initialRelation = "Spouse"}) {
    final int dependentsCount = _matchingAccountsList.where((a) => !a.isPrimary).length;
    if (dependentsCount >= 6) {
      _showValidationBanner("You have reached the maximum limit of 6 family members for this account.");
      return;
    }

    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String selectedRelation = initialRelation;
    String selectedGender = (initialRelation == "Mother" || initialRelation == "Sister")
        ? "Female"
        : (initialRelation == "Father" || initialRelation == "Brother")
            ? "Male"
            : (initialRelation == "Spouse" ? "Female" : "Male");
    String? localError;
    bool isSavingDependent = false;

    final List<Map<String, dynamic>> relations = [
      {"label": "Spouse", "icon": Icons.favorite_rounded, "color": const Color(0xFF2563EB)},
      {"label": "Child", "icon": Icons.child_care_rounded, "color": const Color(0xFF2563EB)},
      {"label": "Father", "icon": Icons.man_rounded, "color": const Color(0xFF2563EB)},
      {"label": "Mother", "icon": Icons.woman_rounded, "color": const Color(0xFF2563EB)},
      {"label": "Brother", "icon": Icons.people_rounded, "color": const Color(0xFF2563EB)},
      {"label": "Sister", "icon": Icons.people_rounded, "color": const Color(0xFF2563EB)},
      {"label": "Other", "icon": Icons.group_add_rounded, "color": const Color(0xFF2563EB)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─ Handle bar ─
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          // ─ Header ─
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(Icons.group_add_rounded, size: 18, color: primaryColor),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Add Family Member",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      "Add dependent ($dependentsCount/6)",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(sheetContext),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          // ─ Relationship Selection ─
                          _buildInputLabel("Relationship *", isDark, false),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: relations.map((rel) {
                              final String label = rel["label"];
                              final IconData icon = rel["icon"];
                              final Color relColor = rel["color"];
                              final isSel = selectedRelation == label;
                              return InkWell(
                                onTap: () {
                                  setDialogState(() => selectedRelation = label);
                                  // Auto-set gender for Mother/Sister
                                  if (label == "Mother" || label == "Sister") {
                                    setDialogState(() => selectedGender = "Female");
                                  } else if (label == "Father" || label == "Brother") {
                                    setDialogState(() => selectedGender = "Male");
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? relColor.withValues(alpha: isDark ? 0.2 : 0.1)
                                        : (isDark ? const Color(0xFF232323) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel ? relColor.withValues(alpha: 0.5) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                      width: isSel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        icon,
                                        size: 14,
                                        color: isSel ? relColor : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 12,
                                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                          color: isSel ? relColor : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // ─ Name Field ─
                          _buildInputLabel("Full Name *", isDark, false),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.]')),
                              LengthLimitingTextInputFormatter(50),
                            ],
                            onChanged: (_) {
                              if (localError != null) setDialogState(() => localError = null);
                            },
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: _inputDecoration(
                              hintText: "Enter full name (e.g. Priya Sharma)",
                              prefixIcon: Icons.person_outline_rounded,
                              isDark: isDark,
                              errorText: localError,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // ─ Gender and Age Row ─
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("Gender", isDark, false),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: _genderOptions.map((g) {
                                        final isSel = selectedGender.toLowerCase() == g.toLowerCase();
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: InkWell(
                                              onTap: () => setDialogState(() => selectedGender = g),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 9),
                                                decoration: BoxDecoration(
                                                  color: isSel
                                                      ? primaryColor
                                                      : (isDark ? const Color(0xFF232323) : const Color(0xFFF8FAFC)),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isSel ? primaryColor : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    g,
                                                    style: TextStyle(
                                                      fontFamily: appPoppinFont,
                                                      fontSize: 12,
                                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                                      color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel("Age", isDark, false),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: ageController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 13.5,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: "Yrs",
                                        hintStyle: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 12,
                                          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF232323) : const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // ─ Submit Button ─
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isSavingDependent ? null : () async {
                                final depName = nameController.text.trim();
                                if (depName.isEmpty || depName.length < 2) {
                                  setDialogState(() => localError = "Please enter a valid name with at least 2 characters.");
                                  return;
                                }

                                setDialogState(() => isSavingDependent = true);

                                final primaryAccount = _matchingAccountsList.firstWhere(
                                  (a) => a.isPrimary,
                                  orElse: () => _matchingAccountsList.isNotEmpty
                                      ? _matchingAccountsList.first
                                      : PatientOption(id: '', name: '', phone: _phoneController.text.trim(), gender: 'Male', dob: ''),
                                );

                                // Compute approximate DOB from age
                                String dob = '';
                                final ageText = ageController.text.trim();
                                if (ageText.isNotEmpty) {
                                  final age = int.tryParse(ageText);
                                  if (age != null && age > 0 && age < 150) {
                                    final birthYear = DateTime.now().year - age;
                                    dob = '01-01-$birthYear';
                                  }
                                }

                                final createdDependent = await _createDependentInBackend(
                                  name: depName,
                                  relation: selectedRelation,
                                  gender: selectedGender,
                                  dob: dob,
                                  parentUserId: primaryAccount.userId.isNotEmpty ? primaryAccount.userId : null,
                                );

                                if (mounted) {
                                  setState(() {
                                    // Remove any temporary entry with same name if existing
                                    _matchingAccountsList.removeWhere((a) => !a.isPrimary && a.name.toLowerCase() == createdDependent.name.toLowerCase());
                                    _matchingAccountsList.add(createdDependent);
                                    _selectPatientAccount(createdDependent);
                                  });
                                }

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isSavingDependent
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Add ${selectedRelation != 'Other' ? selectedRelation : 'Dependent'} & Schedule",
                                          style: const TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  },
);
}

  // ── 5. Treatment Plans & Procedures Section (Always Available) ──
  Widget _buildTreatmentPlansSection(bool isDark, bool isTab) {
    final query = _treatmentPlanSearchController.text.trim().toLowerCase();
    final displayedPlans = query.isEmpty
        ? _allTreatmentPlans
        : _allTreatmentPlans.where((p) => p.name.toLowerCase().contains(query) || p.description.toLowerCase().contains(query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _treatmentPlanSearchController,
          onChanged: (val) => setState(() {}),
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12.5,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          decoration: _inputDecoration(
            hintText: "Search clinical procedures / packages...",
            prefixIcon: Icons.search_rounded,
            isDark: isDark,
            suffixIcon: _treatmentPlanSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    onPressed: () {
                      setState(() => _treatmentPlanSearchController.clear());
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),

        if (_isLoadingTreatmentPlans)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Loading procedures & treatment plans...",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (displayedPlans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              query.isNotEmpty
                  ? "No procedure found matching '$query'."
                  : "No configured treatment plans found.",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          )
        else ...[
          if (_selectedTreatmentPlanIds.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_selectedTreatmentPlanIds.length} Procedure(s) selected",
                  style: const TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTreatmentPlanIds.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      "Clear All",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Scrollbar(
              controller: _treatmentPlanScrollCtrl,
              thumbVisibility: displayedPlans.length > 3,
              radius: const Radius.circular(4),
              thickness: 3.5,
              child: ListView.separated(
                controller: _treatmentPlanScrollCtrl,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 4),
                itemCount: displayedPlans.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final plan = displayedPlans[index];
                  final isSelected = _selectedTreatmentPlanIds.contains(plan.id);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTreatmentPlanIds.remove(plan.id);
                        } else {
                          _selectedTreatmentPlanIds.add(plan.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
                            : (isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: isSelected ? primaryColor : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan.name,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                if (plan.description.isNotEmpty)
                                  Text(
                                    plan.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 10.5,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "₹${plan.amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDoctorDropdownShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF232323) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF8FAFC),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232323) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsShimmer(bool isDark, bool isTab) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF232323) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF8FAFC),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTab ? 4 : 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232323) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildFullAppointmentShimmer(bool isDark, bool isTab) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF232323) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isTab ? 32 : 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isTab ? 24 : 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232323) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 140, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(width: 100, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(width: 90, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTab ? 4 : 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
