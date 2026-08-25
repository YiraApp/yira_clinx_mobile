import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
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

class PreviousAppointmentOption {
  final int id;
  final String appointmentDate;
  final String startTime;
  final String appointmentType;
  final String status;
  final String reason;
  final String doctorName;
  final String patientName;

  const PreviousAppointmentOption({
    required this.id,
    required this.appointmentDate,
    required this.startTime,
    required this.appointmentType,
    required this.status,
    required this.reason,
    required this.doctorName,
    required this.patientName,
  });
}

class AddNewAppointmentScreen extends StatefulWidget {
  final String? initialPatientName;
  final String? initialPatientPhone;

  const AddNewAppointmentScreen({
    super.key,
    this.initialPatientName,
    this.initialPatientPhone,
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
  bool _isLoadingSlots = false;
  bool _isExistingPatient = false;
  List<DoctorSlotItem> _allDoctorSlots = [];

  // Link to Another Appointment
  bool _linkToExistingAppointment = false;
  int? _selectedParentAppointmentId;
  List<PreviousAppointmentOption> _patientPreviousAppointments = [];
  bool _isLoadingPatientAppointments = false;

  // Configured Treatment Plans for the Hospital
  List<TreatmentPlanOption> _allTreatmentPlans = [];
  final Set<String> _selectedTreatmentPlanIds = {};
  bool _isLoadingTreatmentPlans = false;
  final TextEditingController _treatmentPlanSearchController = TextEditingController();

  // Consultation Fee & Discount State
  bool _includeConsultationFee = true;
  double _consultationFee = 500.0;
  final TextEditingController _discountController = TextEditingController();

  final List<String> _visitTypes = const ["Consultation", "Follow-up", "Check-up", "Tele-Consult"];
  final List<String> _genderOptions = const ["Male", "Female", "Other"];

  void _clearSelectedPatient() {
    setState(() {
      _patientSearchController.clear();
      _selectedGender = "Male";
      _isExistingPatient = false;
      _selectedPatient = null;
      _showPatientDropdown = false;
      _linkToExistingAppointment = false;
      _selectedParentAppointmentId = null;
      _patientPreviousAppointments = [];
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
      _patientSearchController.text = account.name;
      _phoneController.text = account.phone;
      _selectedGender = account.gender.isNotEmpty ? account.gender : "Male";
      _isExistingPatient = true;
      _showPatientDropdown = false;
      _nameError = null;
      _phoneError = null;
    });
    _patientFocusNode.unfocus();
    if (account.phone.isNotEmpty) {
      _fetchPatientPreviousAppointments(account.phone);
    }
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
              accounts.add(PatientOption(
                id: (item['id'] ?? item['userId'] ?? '').toString(),
                userId: (item['userId'] ?? item['id'] ?? '').toString(),
                name: (item['name'] ?? '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}').toString().trim(),
                phone: (item['phone'] ?? cleanPhone).toString(),
                gender: (item['gender'] ?? 'Male').toString(),
                dob: (item['dob'] ?? '').toString(),
                email: (item['email'] ?? '').toString(),
                relation: (item['relation'] ?? 'Self').toString(),
                isPrimary: item['isPrimary'] == true,
                parentUserId: item['parentUserId']?.toString(),
                accountType: (item['accountType'] ?? (item['isPrimary'] == true ? 'Independent' : 'Dependent')).toString(),
                pastAppointmentsCount: int.tryParse((item['pastAppointmentsCount'] ?? '0').toString()) ?? 0,
                lastVisitDate: item['lastVisitDate']?.toString(),
              ));
            }
          }

          if (mounted) {
            setState(() {
              _matchingAccountsList = accounts;
              // Do NOT automatically select the account directly on fetching details.
              // Keep matching accounts and family member options visible so the user can choose or book for their child.
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
        _isExistingPatient = false;
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
      final int orgId = currentUser?.data?.latestOrgId ?? 1;
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
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

  Future<void> _fetchPatientPreviousAppointments(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) return;

    setState(() {
      _isLoadingPatientAppointments = true;
    });
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final int orgId = currentUser?.data?.latestOrgId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.patientAppointmentsUrl,
        data: {
          "patientPhone": cleanPhone,
          "orgId": orgId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      final List<PreviousAppointmentOption> list = [];
      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final items = rawData['data'];
        if (items is List) {
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              final int id = int.tryParse((item['id'] ?? '0').toString()) ?? 0;
              if (id > 0) {
                list.add(PreviousAppointmentOption(
                  id: id,
                  appointmentDate: (item['appointmentDate'] ?? '').toString(),
                  startTime: (item['startTime'] ?? '').toString(),
                  appointmentType: (item['appointmentType'] ?? 'Consultation').toString(),
                  status: (item['status'] ?? 'Scheduled').toString(),
                  reason: (item['reason'] ?? '').toString(),
                  doctorName: (item['doctorName'] ?? 'Doctor').toString(),
                  patientName: (item['patientName'] ?? 'Patient').toString(),
                ));
              }
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _patientPreviousAppointments = list;
          if (_patientPreviousAppointments.isNotEmpty && _selectedParentAppointmentId == null) {
            _selectedParentAppointmentId = _patientPreviousAppointments.first.id;
          }
        });
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() {
          _isLoadingPatientAppointments = false;
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
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
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
        if (slotData != null && slotData['slots'] is List) {
          final List<dynamic> rawSlots = slotData['slots'] as List;
          for (final item in rawSlots) {
            if (item is Map<String, dynamic>) {
              final String label = (item['label'] ?? '').toString();
              final bool isAvail = item['isAvailable'] == true;
              final bool isBooked = item['isBooked'] == true;
              final bool isBlocked = item['isBlocked'] == true || (!isAvail && !isBooked);
              if (label.isNotEmpty) {
                fetched.add(DoctorSlotItem(
                  id: (item['id'] ?? '').toString(),
                  startTime: (item['startTime'] ?? '').toString(),
                  endTime: (item['endTime'] ?? '').toString(),
                  label: label,
                  isAvailable: isAvail,
                  isBooked: isBooked,
                  isBlocked: isBlocked,
                  patientName: (item['patientName'] ?? '').toString(),
                  appointmentType: (item['appointmentType'] ?? '').toString(),
                ));
              }
            }
          }
        }
        // Parse consultation fee from the slots API response
        if (slotData != null && slotData['consultationFee'] != null) {
          final fee = double.tryParse(slotData['consultationFee'].toString()) ?? 0;
          if (mounted) {
            setState(() {
              _consultationFee = fee > 0 ? fee : 500.0;
            });
          }
        }
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
          return PatientOption(id: id, name: name, phone: phone, gender: gender, dob: dob, email: email);
        }).where((p) => p.name.trim().isNotEmpty && p.name != 'Patient').toList();

        if (mounted) {
          setState(() {
            _apiPatientsList = fetched;
          });
        }
      }
    } catch (_) {}
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

  @override
  void initState() {
    super.initState();
    _patientFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showPatientDropdown = _patientFocusNode.hasFocus;
        });
      }
    });
    final currentUser = GlobalSession.instance.userNotifier.value?.data;
    if (currentUser != null) {
      final name = currentUser.firstName ?? currentUser.email?.split('@').first ?? '';
      if (name.isNotEmpty) {
        _selectedDoctor = "Dr. $name";
      }
    }
    if (widget.initialPatientName != null && widget.initialPatientName!.isNotEmpty) {
      _patientSearchController.text = widget.initialPatientName!;
      _isExistingPatient = true;
    }
    if (widget.initialPatientPhone != null && widget.initialPatientPhone!.isNotEmpty) {
      _phoneController.text = widget.initialPatientPhone!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
        _fetchPatientsFromApi();
        _fetchDoctorSlots(_selectedDate);
        _fetchTreatmentPlans();
        if (_phoneController.text.trim().isNotEmpty) {
          _fetchPatientPreviousAppointments(_phoneController.text.trim());
        }
      }
    });
  }

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
      setState(() => _phoneError = "10-digit mobile number is required");
      hasError = true;
    } else if (digitsPhone.length != 10) {
      setState(() => _phoneError = "Mobile number must be exactly 10 digits");
      hasError = true;
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digitsPhone)) {
      setState(() => _phoneError = "Mobile number must start with 6, 7, 8, or 9");
      hasError = true;
    }

    if (name.isEmpty) {
      setState(() => _nameError = "Patient name is required");
      hasError = true;
    } else if (name.length < 2) {
      setState(() => _nameError = "Name must be at least 2 characters");
      hasError = true;
    }

    final hasValidSlot = _allDoctorSlots.any((s) => s.label == _selectedSlot && s.isSelectableForDate(_selectedDate));
    if (!hasValidSlot || _selectedSlot.trim().isEmpty) {
      setState(() => _slotError = "Please select an upcoming available consultation slot");
      hasError = true;
    }

    if (reason.isEmpty) {
      setState(() => _reasonError = "Consultation reason is required");
      hasError = true;
    } else if (reason.length < 2) {
      setState(() => _reasonError = "Reason must be at least 2 characters");
      hasError = true;
    }

    final double discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
    final double consultationFeeAmt = _includeConsultationFee ? _consultationFee : 0.0;
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
      _showValidationBanner("Discount (₹${discount.toStringAsFixed(0)}) cannot exceed total bill (₹${grossTotal.toStringAsFixed(0)})");
      return;
    }

    if (hasError) {
      _showValidationBanner("Please correct the highlighted fields before booking");
      return;
    }

    final startTimeStr = _selectedSlot.split(" - ").first.trim();
    final formattedTime = startTimeStr.contains(":") ? "$startTimeStr:00" : "10:00:00";

    context.read<AppointmentBloc>().add(
      SubmitBookAppointmentEvent(
        patientUserId: _selectedPatient?.userId.isNotEmpty == true ? _selectedPatient!.userId : null,
        parentUserId: _selectedPatient?.parentUserId,
        relation: _selectedPatient?.relation ?? "Self",
        isPrimary: _selectedPatient?.isPrimary ?? true,
        patientName: name,
        phoneNumber: digitsPhone,
        patientEmail: _selectedPatient?.email,
        gender: _selectedPatient?.gender.isNotEmpty == true ? _selectedPatient!.gender : _selectedGender,
        dob: _selectedPatient?.dob.isNotEmpty == true ? _selectedPatient!.dob : DateFormat('yyyy-MM-dd').format(_selectedDate),
        appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime: formattedTime,
        reason: reason,
        appointmentType: _selectedVisitType,
        isTeleConsultation: _isTeleConsultation,
        parentAppointmentId: (_isExistingPatient && _linkToExistingAppointment) ? _selectedParentAppointmentId : null,
        treatmentPlanIds: _selectedTreatmentPlanIds.isNotEmpty ? _selectedTreatmentPlanIds.toList() : null,
        discountAmount: discount > 0 ? discount : null,
        includeConsultationFee: _includeConsultationFee,
        consultationFee: _includeConsultationFee ? _consultationFee : 0.0,
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

  void _showSuccessSheet(BuildContext context, BookAppointmentSuccessState state) {
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
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          "Patient",
                          state.patientName ?? _patientSearchController.text,
                          Icons.person_outline_rounded,
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          "Schedule",
                          "${DateFormat('dd MMM yyyy').format(_selectedDate)} • $_selectedSlot",
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
                        if (_linkToExistingAppointment && _selectedParentAppointmentId != null) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            "Linked Visit",
                            "Connected to Appointment #$_selectedParentAppointmentId",
                            Icons.link_rounded,
                            isDark,
                            highlight: true,
                          ),
                        ],
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return BlocConsumer<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state is BookAppointmentSuccessState) {
          _showSuccessSheet(context, state);
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

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
            title: Text(
              "New Appointment",
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
          body: SingleChildScrollView(
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
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                          _buildSectionHeader(1, "Patient Details", isDark),
                          if (_selectedPatient != null)
                            InkWell(
                              onTap: _clearSelectedPatient,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Change ✕",
                                  style: TextStyle(
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
                      const SizedBox(height: 12),

                      if (_selectedPatient != null) ...[
                        _buildSelectedPatientCard(isDark, isTab),
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
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                      _buildSectionHeader(2, "Date & Available Slot", isDark),
                      const SizedBox(height: 14),

                      _buildInputLabel("Consultation Date *", isDark, isTab),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _showDatePicker(context, _selectedDate, isDark),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                                "Checking available slots...",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_allDoctorSlots.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                      _buildSectionHeader(3, "Consultation Details", isDark),
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
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                ),
                              ),
                              child: Text(
                                type,
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

                      _buildInputLabel("Reason / Chief Complaint *", isDark, isTab),
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
                          hintText: "Enter primary complaint or purpose of visit...",
                          prefixIcon: Icons.edit_note_rounded,
                          isDark: isDark,
                          errorText: _reasonError,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Teleconsultation row
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
                                }
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 18),

                      // 4. Treatment Plans & Procedures (Always Available)
                      _buildSectionHeader(4, "Treatment Plans & Procedures", isDark),
                      const SizedBox(height: 12),
                      _buildTreatmentPlansSection(isDark, isTab),

                      if (_isExistingPatient && _patientPreviousAppointments.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _buildLinkToPreviousAppointmentCard(isDark, isTab),
                      ],

                      const SizedBox(height: 18),
                      Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 18),

                      // 5. Billing & Payment
                      _buildSectionHeader(5, "Billing & Payment", isDark),
                      const SizedBox(height: 14),

                      // Consultation fee toggle row
                      Row(
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
                      ),
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
                                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
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
                      const SizedBox(height: 14),

                      // Compact Bill Summary
                      Builder(
                        builder: (context) {
                          final double discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
                          final double consultationFeeAmt = _includeConsultationFee ? _consultationFee : 0.0;

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
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                  ),
                ),
                const SizedBox(height: 20),

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
                              gradient: isSubmitting
                                  ? const LinearGradient(
                                      colors: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                    ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: isSubmitting ? 0.2 : 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
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
                                      children: const [
                                        Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          "Confirm & Book Appointment",
                                          style: TextStyle(
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

  // ── Doctor Info Header (Clean Row) ──
  Widget _buildDoctorHeader(bool isDark, bool isTab) {
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

  // ── Grouped Slots View ──
  Widget _buildGroupedSlotsView(bool isDark, bool isTab) {
    final morningSlots = _allDoctorSlots.where((s) => s.startHour < 12).toList();
    final afternoonSlots = _allDoctorSlots.where((s) => s.startHour >= 12 && s.startHour < 17).toList();
    final eveningSlots = _allDoctorSlots.where((s) => s.startHour >= 17).toList();

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
    final String displayTime = slot.startTime.length >= 5 ? slot.startTime.substring(0, 5) : slot.startTime;

    if (!isSelectable) {
      final bool isBooked = slot.isBooked;
      final String statusLabel = isPast
          ? "Passed"
          : isBooked
              ? "Booked"
              : "Blocked";

      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2633) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
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
              Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                ),
              ),
            ],
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
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
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
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
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
                        });
                        _fetchDoctorSlots(_selectedDate);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
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

  Widget _buildLinkToPreviousAppointmentCard(bool isDark, bool isTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Link to Previous Appointment",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "Connect to prior visit or follow-up session",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Switch.adaptive(
              value: _linkToExistingAppointment,
              activeTrackColor: primaryColor,
              activeThumbColor: Colors.white,
              onChanged: (val) {
                setState(() {
                  _linkToExistingAppointment = val;
                  if (val && _patientPreviousAppointments.isEmpty && _phoneController.text.trim().isNotEmpty) {
                    _fetchPatientPreviousAppointments(_phoneController.text.trim());
                  }
                });
              },
            ),
          ],
        ),
        if (_linkToExistingAppointment) ...[
          const SizedBox(height: 10),
          if (_isLoadingPatientAppointments)
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
                      "Fetching prior consultations...",
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
          else if (_patientPreviousAppointments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                "No prior appointments found for this patient.",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            )
          else ...[
            _buildInputLabel("Select Prior Appointment", isDark, isTab),
            const SizedBox(height: 6),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patientPreviousAppointments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final appt = _patientPreviousAppointments[index];
                final isSelected = _selectedParentAppointmentId == appt.id;

                String formattedDate = appt.appointmentDate;
                try {
                  final parsed = DateTime.parse(appt.appointmentDate);
                  formattedDate = DateFormat('dd MMM yyyy').format(parsed);
                } catch (_) {}

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedParentAppointmentId = appt.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
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
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 16,
                          color: isSelected ? primaryColor : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$formattedDate • ${appt.startTime.length >= 5 ? appt.startTime.substring(0, 5) : appt.startTime} (${appt.appointmentType})",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              if (appt.doctorName.isNotEmpty)
                                Text(
                                  "Doctor: ${appt.doctorName}",
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
                  ),
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  // ── 1. Patient Search Mode Tabs (Two Distinct Options) ──
  Widget _buildPatientSearchModeTabs(bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
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
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
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
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
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
    final Color accentColor = isIndependent ? const Color(0xFF2563EB) : const Color(0xFF059669);

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
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ Accent top strip ─
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.4)],
                  ),
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withValues(alpha: 0.2),
                                accentColor.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.3),
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
                          onTap: _clearSelectedPatient,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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
                    const SizedBox(height: 10),
                    // ─ Contact Info Row ─
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_rounded,
                            size: 13,
                            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "+91 ${patient.phone}",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          if (patient.dob.isNotEmpty) ...[
                            Container(
                              width: 1,
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                            ),
                            Icon(
                              Icons.cake_rounded,
                              size: 13,
                              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              patient.dob,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ],
                          if (patient.email != null && patient.email!.isNotEmpty) ...[
                            Container(
                              width: 1,
                              height: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                            ),
                            Icon(
                              Icons.email_outlined,
                              size: 13,
                              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                patient.email!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // ─ Past visits badge ─
                    if (patient.pastAppointmentsCount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
                              const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.10 : 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_rounded, size: 13, color: Color(0xFF6366F1)),
                            const SizedBox(width: 5),
                            Text(
                              "${patient.pastAppointmentsCount} Prior Consultation(s)",
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            if (patient.lastVisitDate != null && patient.lastVisitDate!.isNotEmpty) ...[
                              Text(
                                " · Last: ${patient.lastVisitDate}",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.7),
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
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                "Searching matching accounts for +91 $cleanPhone...",
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
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
            // ─ Accent strip ─
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.3)],
                ),
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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withValues(alpha: 0.2),
                              primaryColor.withValues(alpha: 0.08),
                            ],
                          ),
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
                              "No accounts found for +91 $cleanPhone",
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
                                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
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
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                  "Matching Accounts (${_matchingAccountsList.length})",
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
            "Select an account to schedule for, or choose a relation below for their child / family member:",
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
              final bool isIndependent = account.isPrimary || account.relation.toLowerCase() == 'self';
              final bool isSelected = _selectedPatient?.id == account.id;
              final Color tileAccent = isIndependent ? const Color(0xFF2563EB) : const Color(0xFF059669);

              // Relation-specific icon
              IconData relationIcon;
              switch (account.relation.toLowerCase()) {
                case 'spouse':
                  relationIcon = Icons.favorite_rounded;
                  break;
                case 'child':
                  relationIcon = Icons.child_care_rounded;
                  break;
                case 'father':
                case 'mother':
                  relationIcon = Icons.family_restroom_rounded;
                  break;
                case 'brother':
                case 'sister':
                  relationIcon = Icons.people_rounded;
                  break;
                default:
                  relationIcon = isIndependent ? Icons.person_rounded : Icons.group_rounded;
              }

              return InkWell(
                onTap: () => _selectPatientAccount(account),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tileAccent.withValues(alpha: isDark ? 0.15 : 0.06)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? tileAccent.withValues(alpha: 0.5)
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: tileAccent.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // ─ Gradient Avatar ─
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tileAccent.withValues(alpha: 0.2),
                              tileAccent.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: tileAccent.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            relationIcon,
                            size: 18,
                            color: tileAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    account.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tileAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isIndependent ? Icons.shield_rounded : Icons.link_rounded,
                                        size: 9,
                                        color: tileAccent,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        isIndependent ? "Primary" : account.relation,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: tileAccent,
                                        ),
                                      ),
                                    ],
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
                                  size: 12,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    "${account.gender}${account.dob.isNotEmpty ? ' · ${account.dob}' : ''}${account.pastAppointmentsCount > 0 ? ' · ${account.pastAppointmentsCount} visit(s)' : ''}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
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
                    _buildQuickRelationChip("Spouse", Icons.favorite_rounded, const Color(0xFFE11D48), isDark),
                    _buildQuickRelationChip("Father", Icons.man_rounded, const Color(0xFF0891B2), isDark),
                    _buildQuickRelationChip("Mother", Icons.woman_rounded, const Color(0xFFD946EF), isDark),
                    _buildQuickRelationChip("Other", Icons.group_add_rounded, const Color(0xFF6366F1), isDark),
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
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String selectedRelation = initialRelation;
    String selectedGender = (initialRelation == "Mother" || initialRelation == "Sister")
        ? "Female"
        : (initialRelation == "Father" || initialRelation == "Brother")
            ? "Male"
            : (initialRelation == "Spouse" ? "Female" : "Male");
    String? localError;

    final List<Map<String, dynamic>> relations = [
      {"label": "Spouse", "icon": Icons.favorite_rounded, "color": const Color(0xFFE11D48)},
      {"label": "Child", "icon": Icons.child_care_rounded, "color": const Color(0xFF2563EB)},
      {"label": "Father", "icon": Icons.man_rounded, "color": const Color(0xFF0891B2)},
      {"label": "Mother", "icon": Icons.woman_rounded, "color": const Color(0xFFD946EF)},
      {"label": "Brother", "icon": Icons.people_rounded, "color": const Color(0xFF059669)},
      {"label": "Sister", "icon": Icons.people_rounded, "color": const Color(0xFFF97316)},
      {"label": "Other", "icon": Icons.group_add_rounded, "color": const Color(0xFF6366F1)},
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
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor.withValues(alpha: 0.2),
                                      primaryColor.withValues(alpha: 0.08),
                                    ],
                                  ),
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
                                      "Add dependent under +91 ${_phoneController.text.trim()}",
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
                                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
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
                                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
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
                                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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
                              onPressed: () {
                                final depName = nameController.text.trim();
                                if (depName.isEmpty || depName.length < 2) {
                                  setDialogState(() => localError = "Please enter a valid name (min 2 chars)");
                                  return;
                                }

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

                                final newDependent = PatientOption(
                                  id: 'DEP-${DateTime.now().millisecondsSinceEpoch}',
                                  userId: '',
                                  name: depName,
                                  phone: _phoneController.text.trim(),
                                  gender: selectedGender,
                                  dob: dob,
                                  relation: selectedRelation,
                                  isPrimary: false,
                                  parentUserId: primaryAccount.userId.isNotEmpty ? primaryAccount.userId : null,
                                  accountType: "Dependent",
                                );

                                setState(() {
                                  _matchingAccountsList.add(newDependent);
                                  _selectPatientAccount(newDependent);
                                });

                                Navigator.pop(sheetContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
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

  // ── 5. Add Custom Treatment Plan Dialog ──
  void _showAddCustomTreatmentPlanDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String? localError;

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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Add Custom Procedure / Plan",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel("Procedure / Service Name *", isDark, false),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            hintText: "e.g. Root Canal Treatment, Blood Test",
                            prefixIcon: Icons.medical_services_outlined,
                            isDark: isDark,
                            errorText: localError,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInputLabel("Fee Amount (₹) *", isDark, false),
                        const SizedBox(height: 6),
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDecoration(
                            hintText: "Enter amount (e.g. 1500)",
                            prefixIcon: Icons.currency_rupee_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                              if (name.isEmpty) {
                                setDialogState(() => localError = "Procedure name is required");
                                return;
                              }
                              if (amt <= 0) {
                                setDialogState(() => localError = "Please enter a valid amount");
                                return;
                              }

                              final newPlan = TreatmentPlanOption(
                                id: "custom-${DateTime.now().millisecondsSinceEpoch}",
                                name: name,
                                description: "Custom procedure added during booking",
                                amount: amt,
                                status: "Active",
                              );

                              setState(() {
                                _allTreatmentPlans.insert(0, newPlan);
                                _selectedTreatmentPlanIds.add(newPlan.id);
                              });

                              Navigator.pop(sheetContext);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              "Add & Include Procedure",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  // ── 6. Treatment Plans & Procedures Section (Always Available) ──
  Widget _buildTreatmentPlansSection(bool isDark, bool isTab) {
    final query = _treatmentPlanSearchController.text.trim().toLowerCase();
    final displayedPlans = query.isEmpty
        ? _allTreatmentPlans
        : _allTreatmentPlans.where((p) => p.name.toLowerCase().contains(query) || p.description.toLowerCase().contains(query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
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
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showAddCustomTreatmentPlanDialog(context, isDark),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.add_rounded, size: 16, color: primaryColor),
                    SizedBox(width: 4),
                    Text(
                      "Custom",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
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
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              query.isNotEmpty
                  ? "No procedure found matching '$query'. Use '+ Custom' to add one."
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
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
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
}
