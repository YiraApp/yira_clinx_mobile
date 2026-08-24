import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class PatientOption {
  final String id;
  final String name;
  final String phone;
  final String gender;
  final String dob;

  const PatientOption({
    required this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.dob,
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

  const DoctorSlotItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.isAvailable,
    required this.isBooked,
    required this.isBlocked,
  });

  bool get isSelectable => isAvailable && !isBooked && !isBlocked;
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

  Timer? _searchDebounce;
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

  final List<String> _visitTypes = const ["Consultation", "Follow-up", "Check-up", "Tele-Consult"];
  final List<String> _genderOptions = const ["Male", "Female", "Other"];

  void _clearSelectedPatient() {
    setState(() {
      _patientSearchController.clear();
      _phoneController.clear();
      _selectedGender = "Male";
      _isExistingPatient = false;
      _showPatientDropdown = false;
      _linkToExistingAppointment = false;
      _selectedParentAppointmentId = null;
      _patientPreviousAppointments = [];
    });
    _patientFocusNode.unfocus();
    context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
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
      if (mounted) {
        setState(() {
          _allTreatmentPlans = list;
        });
      }
    } catch (_) {} finally {
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
                ));
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _allDoctorSlots = fetched;
          final availableSlots = _allDoctorSlots.where((s) => s.isSelectable).toList();
          if (availableSlots.isNotEmpty) {
            if (!_allDoctorSlots.any((s) => s.label == _selectedSlot && s.isSelectable)) {
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
          return PatientOption(id: id, name: name, phone: phone, gender: gender, dob: dob);
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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 16),
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
    _patientSearchController.dispose();
    _patientFocusNode.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
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
                // Top Doctor / Facility Banner
                _buildDoctorHeader(isDark, isTab),
                const SizedBox(height: 16),

                // 1. Patient Information Card
                _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: "Patient Details",
                  subtitle: _isExistingPatient
                      ? "Existing patient profile linked"
                      : "Search existing patient or enter new details",
                  trailing: _isExistingPatient
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            ),
                          ),
                          child: InkWell(
                            onTap: _clearSelectedPatient,
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.lock_rounded, size: 12, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text(
                                  "Existing",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.close_rounded, size: 13, color: Color(0xFF1D4ED8)),
                              ],
                            ),
                          ),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Patient Name *", isDark, isTab),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _patientSearchController,
                        focusNode: _patientFocusNode,
                        onChanged: (val) {
                          setState(() {
                            _showPatientDropdown = true;
                            if (_isExistingPatient) {
                              _isExistingPatient = false;
                            }
                          });
                          _onPatientSearchChanged(val);
                        },
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 15 : 13.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _inputDecoration(
                          hintText: "Search patient by name or phone...",
                          prefixIcon: Icons.search_rounded,
                          isDark: isDark,
                          suffixIcon: _patientSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: _clearSelectedPatient,
                                )
                              : null,
                        ),
                      ),
                      if ((_patientFocusNode.hasFocus || _showPatientDropdown) && filteredPatients.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Material(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 210),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shrinkWrap: true,
                              itemCount: filteredPatients.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (context, index) {
                                final patient = filteredPatients[index];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                                    child: Text(
                                      patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    patient.name,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Phone: ${patient.phone.isNotEmpty ? patient.phone : "N/A"}  •  ID: ${patient.id}',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _patientSearchController.text = patient.name;
                                      if (patient.phone.isNotEmpty) {
                                        _phoneController.text = patient.phone;
                                      }
                                      if (patient.gender.isNotEmpty) {
                                        _selectedGender = patient.gender;
                                      }
                                      _isExistingPatient = true;
                                      _showPatientDropdown = false;
                                    });
                                    _patientFocusNode.unfocus();
                                    if (patient.phone.isNotEmpty) {
                                      _fetchPatientPreviousAppointments(patient.phone);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInputLabel("Patient Phone Number *", isDark, isTab),
                          if (_isExistingPatient)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 13,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Locked",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        readOnly: _isExistingPatient,
                        keyboardType: TextInputType.phone,
                        onChanged: (v) {
                          if (v.replaceAll(RegExp(r'\D'), '').length >= 10) {
                            _fetchPatientPreviousAppointments(v);
                          }
                        },
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 15 : 13.5,
                          color: _isExistingPatient
                              ? (isDark ? Colors.white70 : const Color(0xFF475569))
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: _isExistingPatient ? FontWeight.w600 : FontWeight.normal,
                        ),
                        decoration: _inputDecoration(
                          hintText: "10-digit mobile number",
                          prefixIcon: _isExistingPatient ? Icons.lock_outline_rounded : Icons.phone_rounded,
                          isDark: isDark,
                          suffixIcon: _isExistingPatient
                              ? const Tooltip(
                                  message: "Mobile number locked for existing contact",
                                  child: Icon(Icons.lock_rounded, size: 17, color: Color(0xFF94A3B8)),
                                )
                              : null,
                        ),
                      ),
                      if (_isExistingPatient) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "Linked to registered contact. Tap 'Existing ✕' above to enter a new contact.",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInputLabel("Gender", isDark, isTab),
                          if (_isExistingPatient)
                            Text(
                              "Locked",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _genderOptions.map((gender) {
                          final isSelected = _selectedGender.toLowerCase() == gender.toLowerCase();
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () {
                                  if (_isExistingPatient) {
                                    _showValidationBanner("Gender is locked for registered patient profile.");
                                    return;
                                  }
                                  setState(() {
                                    _selectedGender = gender;
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Opacity(
                                  opacity: _isExistingPatient && !isSelected ? 0.4 : 1.0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
                                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (_isExistingPatient && isSelected) ...[
                                            const Icon(Icons.lock_rounded, size: 12, color: primaryColor),
                                            const SizedBox(width: 4),
                                          ],
                                          Text(
                                            gender,
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: 12.5,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                              color: isSelected
                                                  ? (isDark ? const Color(0xFF60A5FA) : primaryColor)
                                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                            ),
                                          ),
                                        ],
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
                const SizedBox(height: 16),

                // 2. Schedule Date & Slot Selection Card
                _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.calendar_month_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: "Appointment Schedule",
                  subtitle: "Choose consultation date and available slot",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Consultation Date *", isDark, isTab),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _showDatePicker(context, _selectedDate, isDark),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      _selectedDate.day == DateTime.now().day &&
                                              _selectedDate.month == DateTime.now().month
                                          ? "Today's Schedule"
                                          : "Scheduled Day",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11,
                                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Change",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInputLabel("Available Slot *", isDark, isTab),
                          if (_allDoctorSlots.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${_allDoctorSlots.where((s) => s.isSelectable).length} available",
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_isLoadingSlots)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
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
                              Text(
                                "Checking available slots...",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12.5,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_allDoctorSlots.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_busy_rounded, color: Colors.amber, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "No slots scheduled for this date. Please pick a different date.",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.amber[200] : Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allDoctorSlots.map((slot) {
                            final bool isSelectable = slot.isSelectable;
                            final bool isSelected = _selectedSlot == slot.label && isSelectable;

                            if (!isSelectable) {
                              // Already Blocked or Booked Slot -> Show in Gray Color!
                              final String badgeText = slot.isBooked ? "Booked" : "Blocked";
                              return Tooltip(
                                message: "Slot ${slot.label} is $badgeText",
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E2633).withValues(alpha: 0.5)
                                        : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white10
                                          : const Color(0xFFCBD5E1).withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        slot.isBooked ? Icons.event_busy_rounded : Icons.block_rounded,
                                        size: 13,
                                        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        slot.label,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Available Slot
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedSlot = slot.label;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      slot.label,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Consultation Details Card
                _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.medical_services_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: "Consultation Details",
                  subtitle: "Set visit type and reason for consultation",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.25 : 0.12)
                                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF8B5CF6)
                                      : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED))
                                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      _buildInputLabel("Reason / Chief Complaint *", isDark, isTab),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _reasonController,
                        maxLines: 3,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 15 : 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: _inputDecoration(
                          hintText: "Enter primary symptoms, complaint or purpose of consultation...",
                          prefixIcon: Icons.notes_rounded,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Link to Previous Appointment Card
                _buildLinkToPreviousAppointmentCard(isDark, isTab),
                const SizedBox(height: 16),

                // 5. Treatment Plans & Procedures Card
                _buildTreatmentPlansCard(isDark, isTab),
                const SizedBox(height: 16),

                // 6. Teleconsultation Feature Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: _isTeleConsultation
                        ? LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E3A8A).withValues(alpha: 0.6), const Color(0xFF1E293B)]
                                : [const Color(0xFFEFF6FF), Colors.white],
                          )
                        : null,
                    color: _isTeleConsultation ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isTeleConsultation
                          ? const Color(0xFF3B82F6)
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      width: _isTeleConsultation ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.videocam_rounded,
                              color: Color(0xFF2563EB),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Teleconsultation (Zoom Video)",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Generates Zoom link & sends WhatsApp invite",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
                      if (_isTeleConsultation) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF2563EB)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Instant Zoom link will be created & sent to patient via WhatsApp.",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 7. Submit Button
                Builder(
                  builder: (context) {
                    final bool isSubmitting = state is BookAppointmentLoadingState;
                    return Column(
                      children: [
                        InkWell(
                          onTap: isSubmitting
                              ? null
                              : () {
                                  final name = _patientSearchController.text.trim();
                                  final rawPhone = _phoneController.text.trim();
                                  final digitsPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
                                  final reason = _reasonController.text.trim();

                                  if (name.isEmpty) {
                                    _showValidationBanner("Please enter patient name");
                                    return;
                                  }

                                  if (name.length < 2) {
                                    _showValidationBanner("Patient name must be at least 2 characters");
                                    return;
                                  }

                                  if (digitsPhone.isEmpty) {
                                    _showValidationBanner("Please enter patient 10-digit mobile number");
                                    return;
                                  }

                                  if (digitsPhone.length != 10) {
                                    _showValidationBanner("Please enter a valid 10-digit mobile number");
                                    return;
                                  }

                                  final hasValidSlot = _allDoctorSlots.any((s) => s.label == _selectedSlot && s.isSelectable);
                                  if (!hasValidSlot || _selectedSlot.trim().isEmpty) {
                                    _showValidationBanner("Please select an available (non-blocked) consultation slot");
                                    return;
                                  }

                                  if (reason.isEmpty) {
                                    _showValidationBanner("Please enter consultation reason or symptoms");
                                    return;
                                  }

                                  final startTimeStr = _selectedSlot.split(" - ").first.trim();
                                  final formattedTime = startTimeStr.contains(":") ? "$startTimeStr:00" : "10:00:00";

                                  context.read<AppointmentBloc>().add(
                                    SubmitBookAppointmentEvent(
                                      patientName: name,
                                      phoneNumber: digitsPhone,
                                      gender: _selectedGender,
                                      dob: DateFormat('yyyy-MM-dd').format(_selectedDate),
                                      appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
                                      startTime: formattedTime,
                                      reason: reason,
                                      appointmentType: _selectedVisitType,
                                      isTeleConsultation: _isTeleConsultation,
                                      parentAppointmentId: _linkToExistingAppointment ? _selectedParentAppointmentId : null,
                                      treatmentPlanIds: _selectedTreatmentPlanIds.isNotEmpty ? _selectedTreatmentPlanIds.toList() : null,
                                    ),
                                  );
                                },
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
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "Scheduling Appointment...",
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          "Book Appointment",
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
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

  Widget _buildDoctorHeader(bool isDark, bool isTab) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor.withValues(alpha: 0.15),
            child: const Icon(Icons.person_outline_rounded, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedDoctor,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "Provider Schedule • Active Session",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  "Live",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
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
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 12.5,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? Colors.white54 : const Color(0xFF64748B),
        size: 18,
      ),
      suffixIcon: suffixIcon,
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
          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaryColor,
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
                        minimumDate: DateTime.now().subtract(const Duration(days: 1)),
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
    return _buildSectionCard(
      isDark: isDark,
      icon: Icons.link_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: "Link to Previous Appointment",
      subtitle: "Connect this booking to a prior visit or follow-up session",
      trailing: Switch.adaptive(
        value: _linkToExistingAppointment,
        activeTrackColor: const Color(0xFFF59E0B),
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
      child: !_linkToExistingAppointment
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (_isLoadingPatientAppointments) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
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
                  ),
                ] else if (_patientPreviousAppointments.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "No prior appointments found for this patient phone.",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _buildInputLabel("Select Prior Appointment to Link *", isDark, isTab),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _patientPreviousAppointments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.08)
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFF59E0B)
                                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 18,
                                  color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "$formattedDate • ${appt.startTime.isNotEmpty ? (appt.startTime.length >= 5 ? appt.startTime.substring(0, 5) : appt.startTime) : ''}",
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                                                : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            appt.appointmentType,
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Doctor: ${appt.doctorName}",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11.5,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                    if (appt.reason.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        "Reason: ${appt.reason}",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
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
            ),
    );
  }

  Widget _buildTreatmentPlansCard(bool isDark, bool isTab) {
    double totalAmount = 0.0;
    for (final planId in _selectedTreatmentPlanIds) {
      final plan = _allTreatmentPlans.firstWhere(
        (p) => p.id == planId,
        orElse: () => const TreatmentPlanOption(id: '', name: '', description: '', amount: 0, status: ''),
      );
      totalAmount += plan.amount;
    }

    final totalSelectedCount = _selectedTreatmentPlanIds.length;

    return _buildSectionCard(
      isDark: isDark,
      icon: Icons.assignment_outlined,
      iconColor: const Color(0xFF06B6D4),
      title: "Treatment Plans & Procedures",
      subtitle: "Configured treatments for this hospital",
      trailing: totalSelectedCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF06B6D4), width: 1),
              ),
              child: Text(
                "$totalSelectedCount selected • ₹${totalAmount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF67E8F9) : const Color(0xFF0891B2),
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingTreatmentPlans) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF06B6D4)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Loading hospital treatment plans...",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_allTreatmentPlans.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "No configured treatment plans found for this hospital.",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildInputLabel("Select Configured Treatment Plan(s)", isDark, isTab),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allTreatmentPlans.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final plan = _allTreatmentPlans[index];
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
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.18 : 0.08)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF06B6D4)
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 20,
                          color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              if (plan.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  plan.description,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "₹${plan.amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? (isDark ? const Color(0xFF67E8F9) : const Color(0xFF0891B2))
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
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
      ),
    );
  }
}
