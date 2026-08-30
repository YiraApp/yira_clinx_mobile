import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/liked_hospitals_service.dart';
import 'package:yiraclinics/core/services/notification_services/notification_services.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/patient/doctors/widgets/scan_doctor_qr_sheet.dart';

class PatientAddNewAppointmentScreen extends StatefulWidget {
  final VoidCallback? onAppointmentBooked;
  final String? initialDoctorId;
  final dynamic initialHospitalId;

  const PatientAddNewAppointmentScreen({
    super.key,
    this.onAppointmentBooked,
    this.initialDoctorId,
    this.initialHospitalId,
  });

  @override
  State<PatientAddNewAppointmentScreen> createState() => _PatientAddNewAppointmentScreenState();
}

class _PatientAddNewAppointmentScreenState extends State<PatientAddNewAppointmentScreen> {
  bool _isLoadingInitial = true;
  bool _isLoadingDoctors = false;
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _hospitals = [];
  List<Map<String, dynamic>> _allDoctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  List<Map<String, dynamic>> _patientProfiles = [];
  List<Map<String, dynamic>> _availableSlots = [];

  Map<String, dynamic>? _selectedHospital;
  Map<String, dynamic>? _selectedDoctor;
  Map<String, dynamic>? _selectedProfile;
  Map<String, dynamic>? _selectedSlot;

  DateTime _selectedDate = DateTime.now();
  String _selectedVisitType = "Consultation";
  bool _isTeleConsultation = false;
  final TextEditingController _reasonController = TextEditingController();
  String? _slotError;

  final List<String> _visitTypes = const ["Consultation", "Follow-up", "Check-up", "Tele-Consult"];
  final List<String> _quickReasons = const [
    "General Checkup",
    "Follow-up",
    "Fever & Cold",
    "Chest Pain",
    "Skin Rash",
    "Routine Consultation"
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingInitial = true);
    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';
    final userId = (currentUser?.data?.id ?? '').toString().trim();
    final primaryPhone = currentUser?.data?.phoneNumber ?? '';

    // 1. Prepare Patient Profiles (Primary + Dependents / Family Members)
    final List<Map<String, dynamic>> profiles = [];
    final userProfiles = currentUser?.data?.profiles ?? [];

    if (userProfiles.isNotEmpty) {
      for (final p in userProfiles) {
        final pId = (p.id ?? '').trim();
        final rawRel = (p.relation ?? '').trim();
        final bool isFam = rawRel.isNotEmpty &&
            rawRel.toLowerCase() != 'self' &&
            rawRel.toLowerCase() != 'primary' &&
            rawRel.toLowerCase() != 'admin';
        final String rel = isFam ? rawRel : (p.isPrimary == true ? 'Self' : 'Dependent');
        final pName = (p.name?.isNotEmpty ?? false)
            ? p.name!
            : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim().isNotEmpty
                ? '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim()
                : rel;

        profiles.add({
          'userId': pId.isNotEmpty ? pId : userId,
          'name': pName,
          'relation': rel,
          'phone': p.phoneNumber ?? primaryPhone,
          'gender': p.gender ?? currentUser?.data?.gender ?? 'Male',
          'isPrimary': p.isPrimary == true && !isFam,
        });
      }
    } else {
      final firstName = currentUser?.data?.firstName ?? 'Patient';
      final lastName = currentUser?.data?.lastName ?? '';
      final fullName = '$firstName $lastName'.trim();

      profiles.add({
        'userId': userId,
        'name': fullName.isNotEmpty ? fullName : 'Self',
        'relation': 'Self',
        'phone': primaryPhone,
        'gender': currentUser?.data?.gender ?? 'Male',
        'isPrimary': true,
      });
    }

    if (primaryPhone.isNotEmpty) {
      try {
        final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
          URLs.patientAccountsByPhoneUrl,
          data: {"phone": primaryPhone},
          options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
        );
        if (res.data != null && res.data['data'] is List) {
          final list = res.data['data'] as List;
          for (final item in list) {
            final itemUserId = (item['id'] ?? item['userId'] ?? '').toString();
            if (itemUserId.isNotEmpty && !profiles.any((p) => p['userId'] == itemUserId)) {
              final fName = (item['firstName'] ?? '').toString();
              final lName = (item['lastName'] ?? '').toString();
              final depName = '$fName $lName'.trim();
              final rel = (item['relation'] ?? 'Dependent').toString();

              profiles.add({
                'userId': itemUserId,
                'name': depName.isNotEmpty ? depName : 'Family Member',
                'relation': rel.isNotEmpty ? rel : 'Dependent',
                'phone': (item['phoneNumber'] ?? primaryPhone).toString(),
                'gender': (item['gender'] ?? 'Other').toString(),
                'isPrimary': item['isPrimary'] == true,
              });
            }
          }
        }
      } catch (_) {}
    }

    _patientProfiles = profiles;

    // Auto-select the active profile (dependent or primary)
    Map<String, dynamic>? activeMatch;
    if (userId.isNotEmpty) {
      final matches = profiles.where((p) => p['userId'] == userId).toList();
      if (matches.isNotEmpty) {
        activeMatch = matches.first;
      }
    }
    _selectedProfile = activeMatch ?? (profiles.isNotEmpty ? profiles.first : null);

    // 2. Load Exclusively Liked & Linked Hospitals
    List<Map<String, dynamic>> hospitals = await LikedHospitalsService.instance.getLikedAndLinkedHospitals(
      patientId: userId,
      initialHospitalId: widget.initialHospitalId,
    );

    // 3. Load Linked Doctors from SharedPreferences
    List<Map<String, dynamic>> doctors = [];
    final linkedStorageKey = userId.isNotEmpty ? 'patient_linked_doctors_$userId' : 'patient_linked_doctors';
    try {
      final prefs = await SharedPreferences.getInstance();
      final localStr = prefs.getString(linkedStorageKey);
      if (localStr != null) {
        final List<dynamic> localList = jsonDecode(localStr);
        for (final item in localList) {
          final map = Map<String, dynamic>.from(item);
          final docId = (map['doctorId'] ?? map['id'] ?? '').toString().trim();
          if (docId.isNotEmpty && !doctors.any((d) => (d['doctorId'] ?? d['id'])?.toString().trim() == docId)) {
            doctors.add(map);
          }
        }
      }
    } catch (_) {}

    // Ensure all doctors' hospitals are present in hospitals list
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

    _hospitals = hospitals;
    _allDoctors = doctors;

    if (widget.initialHospitalId != null) {
      final foundHosp = hospitals.where((h) => h['id'].toString() == widget.initialHospitalId.toString()).toList();
      _selectedHospital = foundHosp.isNotEmpty ? foundHosp.first : (hospitals.isNotEmpty ? hospitals.first : null);
    } else {
      _selectedHospital = hospitals.isNotEmpty ? hospitals.first : null;
    }

    if (_selectedHospital != null) {
      _filterDoctorsForHospital(_selectedHospital!['id']);
    } else {
      _filteredDoctors = [];
      _selectedDoctor = null;
    }

    if (widget.initialDoctorId != null) {
      final foundDoc = _allDoctors.where((d) => (d['doctorId'] ?? d['id']).toString() == widget.initialDoctorId.toString()).toList();
      if (foundDoc.isNotEmpty) {
        _selectedDoctor = foundDoc.first;
      }
    }

    if (mounted) {
      setState(() => _isLoadingInitial = false);
      if (_selectedDoctor != null && _selectedHospital != null) {
        _fetchSlots();
      }
    }
  }

  Future<void> _filterDoctorsForHospital(dynamic hospitalId) async {
    if (hospitalId == null) {
      if (mounted) {
        setState(() {
          _filteredDoctors = [];
          _selectedDoctor = null;
        });
      }
      return;
    }

    setState(() => _isLoadingDoctors = true);
    try {
      final docs = await LikedHospitalsService.instance.getLinkedDoctorsForHospital(
        hospitalId: hospitalId,
        initialDoctor: widget.initialDoctorId != null ? {'doctorId': widget.initialDoctorId} : null,
      );

      if (!mounted) return;

      setState(() {
        _filteredDoctors = docs;
        _selectedDoctor = _filteredDoctors.isNotEmpty ? _filteredDoctors.first : null;
      });
    } finally {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }

    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    if (_selectedDoctor == null || _selectedHospital == null) {
      setState(() {
        _availableSlots = [];
        _selectedSlot = null;
        _isLoadingSlots = false;
      });
      return;
    }

    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
      _slotError = null;
      _availableSlots = [];
    });

    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';
    final doctorId = _selectedDoctor!['doctorId'].toString();
    final hospId = _selectedHospital!['id'];
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    List<Map<String, dynamic>> slots = [];

    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.doctorSlotsUrl,
        data: {
          "doctorId": doctorId,
          "hospitalId": hospId,
          "date": dateStr,
        },
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );

      List<dynamic>? rawSlots;
      if (res.data != null && res.data['data'] != null) {
        final slotData = res.data['data'];
        if (slotData is List) {
          rawSlots = slotData;
        } else if (slotData is Map && slotData['slots'] is List) {
          rawSlots = slotData['slots'] as List;
        }
      }

      if (rawSlots != null && rawSlots.isNotEmpty) {
        final now = DateTime.now();
        final isToday = _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day;

        for (final item in rawSlots) {
          if (item is Map<String, dynamic>) {
            final String startTime = (item['startTime'] ?? '09:00').toString();
            final String endTime = (item['endTime'] ?? '09:15').toString();
            final String label = (item['label'] ?? startTime).toString();

            final bool isBooked = item['isBooked'] == true ||
                item['status']?.toString().toLowerCase() == 'booked' ||
                (item['appointmentId'] != null &&
                    item['appointmentId'].toString().isNotEmpty &&
                    item['appointmentId'].toString() != 'null') ||
                item['hasAppointment'] == true;

            final bool isBlocked = item['isBlocked'] == true ||
                item['status']?.toString().toLowerCase() == 'blocked' ||
                item['label']?.toString().toLowerCase() == 'blocked';

            bool isPast = false;
            if (isToday) {
              final slotDt = DoctorSlotItem.parseSlotDateTime(_selectedDate, startTime);
              if (slotDt != null && slotDt.isBefore(now)) {
                isPast = true;
              }
            }

            final bool isAvail = (item['isAvailable'] == true) && !isBooked && !isBlocked && !isPast;

            slots.add({
              'id': item['id'],
              'startTime': startTime,
              'endTime': endTime,
              'label': label,
              'isAvailable': isAvail,
              'isBooked': isBooked,
              'isBlocked': isBlocked,
              'isPast': isPast,
            });
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
        final firstAvail = slots.where((s) => s['isAvailable'] == true).toList();
        if (firstAvail.isNotEmpty) {
          _selectedSlot = firstAvail.first;
        } else {
          _selectedSlot = null;
        }
      });
    }
  }

  void _showDatePickerModal(BuildContext context, bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF2563EB),
                    surface: Color(0xFF1E293B),
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF2563EB),
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSlots();
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an assigned doctor")),
      );
      return;
    }
    if (_selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a hospital facility")),
      );
      return;
    }
    if (_selectedSlot == null) {
      setState(() => _slotError = "Please select a consultation time slot");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an available consultation slot")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';
    final profile = _selectedProfile ?? _patientProfiles.first;

    final String doctorId = _selectedDoctor!['doctorId'].toString();
    final int hospitalId = int.tryParse(_selectedHospital!['id'].toString()) ?? 1;
    final int orgId = int.tryParse(_selectedHospital!['orgId'].toString()) ?? (currentUser?.data?.latestOrgId ?? 1);
    final String appointmentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final String startTime = _selectedSlot!['startTime'] ?? '09:00';
    final String reason = _reasonController.text.trim().isNotEmpty
        ? _reasonController.text.trim()
        : "General Consultation";

    final body = {
      "doctorId": doctorId,
      "orgId": orgId,
      "hospitalId": hospitalId,
      "patientUserId": profile['userId'],
      "parentUserId": profile['isPrimary'] == true
          ? null
          : (GlobalSession.instance.rootPrimaryUserId ?? currentUser?.data?.id),
      "relation": profile['relation'] ?? "Self",
      "isPrimary": profile['isPrimary'] ?? true,
      "patientName": profile['name'] ?? "Patient",
      "patientPhone": profile['phone'] ?? currentUser?.data?.phoneNumber ?? "",
      "gender": profile['gender'] ?? "Male",
      "appointmentDate": appointmentDate,
      "startTime": startTime,
      "reason": reason,
      "appointmentType": _isTeleConsultation ? "Video" : "Consultation",
      "isTeleConsultation": _isTeleConsultation,
      "consultationFee": _selectedDoctor!['consultationFee'] ?? 0,
    };

    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: true).post(
        URLs.bookAppointmentUrl,
        data: body,
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        widget.onAppointmentBooked?.call();
        _showSuccessSheet(context);
        return;
      }
    } catch (e) {
      debugPrint("Booking Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessSheet(BuildContext ctx) {
    if (_selectedDoctor != null) {
      LikedHospitalsService.instance.saveLinkedDoctor(_selectedDoctor!);
    }
    if (_selectedHospital != null) {
      LikedHospitalsService.instance.saveLikedHospital(_selectedHospital!);
    }

    // Trigger immediate local notification to alert patient instantly
    try {
      final rawDocName = (_selectedDoctor?['name'] ?? 'Doctor').toString().trim();
      final cleanDocName = rawDocName.replaceFirst(RegExp(r'^(Dr\.\s*|Dr\s+|Doctor\s*)', caseSensitive: false), '').trim();
      final formattedDocName = cleanDocName.isNotEmpty ? 'Dr. $cleanDocName' : 'your doctor';
      final dateFormatted = DateFormat('dd MMM yyyy').format(_selectedDate);
      final slotTime = _selectedSlot?['startTime'] ?? '10:00 AM';
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

    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    showModalBottomSheet(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Appointment Booked Successfully!",
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
                "Your consultation has been scheduled and synced.",
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
                      "Doctor",
                      _selectedDoctor?['name'] ?? 'Doctor',
                      Icons.person_outline_rounded,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      "Hospital",
                      _selectedHospital?['name'] ?? 'Facility',
                      Icons.local_hospital_outlined,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      "Schedule",
                      "${DateFormat('dd MMM yyyy').format(_selectedDate)} • ${_selectedSlot?['label'] ?? ''}",
                      Icons.event_available_rounded,
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      "Visit Mode",
                      _isTeleConsultation ? "Video Consultation (Zoom)" : "In-Clinic Visit",
                      _isTeleConsultation ? Icons.videocam_rounded : Icons.storefront_rounded,
                      isDark,
                      highlight: _isTeleConsultation,
                    ),
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
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTab = isTablet(context);

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
      body: _isLoadingInitial
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
                  // Unified Form Container Matching Doctor Screen
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
                        // 1. HOSPITAL & ASSIGNED DOCTOR SELECTION
                        _buildSectionHeader(1, "Hospital & Assigned Doctor", isDark),
                        const SizedBox(height: 12),

                        if (_hospitals.isEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
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
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.local_hospital_rounded,
                                    color: Color(0xFF2563EB),
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
                                    backgroundColor: const Color(0xFF2563EB),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    ScanDoctorQrSheet.show(
                                      context,
                                      onDoctorLinked: (newDoc) {
                                        _loadInitialData();
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
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInputLabel("Hospital / Facility *", isDark, isTab),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Liked / Linked Only",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0284C7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, dynamic>>(
                                value: _selectedHospital,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB)),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: _hospitals.map((h) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: h,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_hospital_rounded, color: Color(0xFF2563EB), size: 18),
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
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedHospital = val;
                                    });
                                    _filterDoctorsForHospital(val['id']);
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          _buildInputLabel("Assigned Doctor *", isDark, isTab),
                          const SizedBox(height: 6),
                          if (_isLoadingDoctors) ...[
                            _buildDoctorCardsShimmer(isDark),
                          ] else if (_filteredDoctors.isEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
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
                                          _loadInitialData();
                                        },
                                      );
                                    },
                                    child: const Text(
                                      "Scan QR",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              height: 88,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _filteredDoctors.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final doc = _filteredDoctors[index];
                                  final isSelected = (_selectedDoctor?['doctorId'] ?? _selectedDoctor?['id']) == (doc['doctorId'] ?? doc['id']);
                                  final docName = doc['name'] ?? 'Doctor';
                                  final initial = docName.replaceFirst('Dr. ', '').trim().isNotEmpty
                                      ? docName.replaceFirst('Dr. ', '').trim()[0].toUpperCase()
                                      : 'D';

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedDoctor = doc);
                                      _fetchSlots();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 220,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE))
                                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2563EB)
                                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                          width: isSelected ? 1.8 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFFBAE6FD),
                                            child: Text(
                                              initial,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : const Color(0xFF0369A1),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  docName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: appPoppinFont,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                                Text(
                                                  doc['specialty'] ?? 'General Physician',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: appPoppinFont,
                                                    fontSize: 10,
                                                    color: Color(0xFF2563EB),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  "₹${doc['consultationFee'] ?? 0}",
                                                  style: TextStyle(
                                                    fontFamily: appPoppinFont,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
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
                            ),
                          ],
                        ],

                        const SizedBox(height: 18),
                        Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        const SizedBox(height: 18),

                        // 2. PATIENT DETAILS (SELF & FAMILY)
                        _buildSectionHeader(2, "Patient Details", isDark),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _patientProfiles.map((p) {
                            final isSelected = _selectedProfile?['userId'] == p['userId'];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedProfile = p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE0F2FE)
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      size: 16,
                                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${p['name']} (${p['relation']})",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 18),
                        Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        const SizedBox(height: 18),

                        // 3. DATE & AVAILABLE SLOTS
                        _buildSectionHeader(3, "Date & Available Slot", isDark),
                        const SizedBox(height: 14),

                        _buildInputLabel("Consultation Date *", isDark, isTab),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _showDatePickerModal(context, isDark),
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
                                const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF2563EB)),
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
                                const Text(
                                  "Change",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 14-day horizontal scroller
                        SizedBox(
                          height: 68,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 14,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final date = DateTime.now().add(Duration(days: index));
                              final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                                  DateFormat('yyyy-MM-dd').format(_selectedDate);
                              final isToday = index == 0;

                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedDate = date);
                                  _fetchSlots();
                                },
                                child: Container(
                                  width: 56,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isToday ? "TODAY" : DateFormat('EEE').format(date).toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('d').format(date),
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInputLabel("Available Slot *", isDark, isTab),
                            if (_availableSlots.isNotEmpty)
                              Text(
                                "${_availableSlots.where((s) => s['isAvailable'] == true).length} open",
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
                          _buildSlotsShimmer(isDark)
                        else if (_availableSlots.isEmpty)
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
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableSlots.map((slot) {
                              final isAvail = slot['isAvailable'] == true;
                              final isBooked = slot['isBooked'] == true;
                              final isPast = slot['isPast'] == true;
                              final isSelected = isAvail && _selectedSlot?['startTime'] == slot['startTime'];
                              final displayLabel = slot['label'] ?? slot['startTime'];

                              return InkWell(
                                onTap: () {
                                  if (isAvail) {
                                    setState(() {
                                      _selectedSlot = slot;
                                      if (_slotError != null) _slotError = null;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isPast
                                              ? "This slot has already passed."
                                              : (isBooked
                                                  ? "This slot is already booked. Please select an available slot."
                                                  : "This slot is currently blocked."),
                                          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12),
                                        ),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : (isAvail
                                            ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))
                                            : (isDark ? const Color(0xFF1E2633) : const Color(0xFFF1F5F9))),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : (isBooked
                                              ? (isDark ? Colors.redAccent.withValues(alpha: 0.25) : Colors.red.withValues(alpha: 0.2))
                                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isBooked) ...[
                                        Icon(
                                          Icons.lock_outline_rounded,
                                          size: 11,
                                          color: isDark ? Colors.redAccent.withValues(alpha: 0.7) : Colors.red.shade400,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        displayLabel,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : (isAvail
                                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                                  : (isBooked
                                                      ? (isDark ? Colors.redAccent.withValues(alpha: 0.7) : Colors.red.shade400)
                                                      : (isDark ? Colors.white24 : Colors.grey.shade400))),
                                          decoration: isAvail ? null : TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

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

                        // 4. CONSULTATION DETAILS (VISIT TYPE & TELECONSULT)
                        _buildSectionHeader(4, "Consultation Details", isDark),
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
                                      ? const Color(0xFF2563EB)
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
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

                        const SizedBox(height: 14),

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
                              activeTrackColor: const Color(0xFF2563EB),
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

                        // 5. REASON / PURPOSE OF VISIT
                        _buildSectionHeader(5, "Reason / Chief Complaint", isDark),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _reasonController,
                          maxLines: 2,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(250),
                          ],
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 15 : 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter primary complaint or purpose of visit...",
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _quickReasons.map((r) {
                            return InkWell(
                              onTap: () => setState(() => _reasonController.text = r),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  r,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedSlot != null
                        ? "${DateFormat('d MMM').format(_selectedDate)} • ${_selectedSlot!['label']}"
                        : "Select a slot",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    _selectedDoctor != null
                        ? "${_selectedDoctor!['name']} (₹${_selectedDoctor!['consultationFee'] ?? 0})"
                        : "Select a doctor",
                    style: const TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: _isSubmitting ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(14),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _isSubmitting ? null : _submitBooking,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Confirm Booking",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int number, String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            "$number",
            style: const TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label, bool isDark, bool isTab) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontWeight: FontWeight.w600,
        fontSize: isTab ? 13 : 11.5,
        color: isDark ? Colors.white70 : const Color(0xFF475569),
      ),
    );
  }

  Widget _buildDoctorCardsShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      child: SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, __) => Container(
            width: 220,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 110, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(width: 75, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(width: 55, height: 9, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
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

  Widget _buildSlotsShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(6, (index) => Container(
          width: 92,
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        )),
      ),
    );
  }

  Widget _buildFullAppointmentShimmer(bool isDark, bool isTab) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isTab ? 32 : 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isTab ? 24 : 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, __) => Container(
                        width: 220,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(6, (index) => Container(
                      width: 92,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    )),
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
