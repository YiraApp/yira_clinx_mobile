import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/core/utils/utils.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/doc_appointment_card.dart';
import 'patient_book_appointment_sheet.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const PatientAppointmentsScreen({super.key, this.onNavigateTab});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  String _activeTab = "upcoming"; // "upcoming" | "completed"
  String _selectedDateLabel = "All Dates";
  DateTimeRange? _customDateRange;
  String _selectedStatus = "All Status";
  bool _isLoading = true;

  List<Map<String, dynamic>> _allAppointments = [];

  final List<String> _dateOptions = const [
    "All Dates",
    "Today",
    "Tomorrow",
    "Date Range",
  ];

  final List<String> _statusOptions = const [
    "All Status",
    "Scheduled",
    "Confirmed",
    "In Progress",
    "Completed",
    "Pending",
    "Cancelled",
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';
    final userId = currentUser?.data?.id ?? '';
    final phone = currentUser?.data?.phoneNumber ?? '';

    List<Map<String, dynamic>> loadedList = [];

    // 1. Fetch from patient-appointments API
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.patientAppointmentsUrl,
        data: {
          "userId": userId,
          "patientPhone": phone,
        },
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );

      if (res.data != null && res.data['data'] is List) {
        final list = res.data['data'] as List;
        for (final a in list) {
          loadedList.add(Map<String, dynamic>.from(a));
        }
      }
    } catch (_) {}

    // 2. Fallback to patient overview if patient-appointments returned empty
    if (loadedList.isEmpty && userId.isNotEmpty) {
      try {
        final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
          URLs.patientOverViewUrl,
          data: {
            "patientId": userId,
            "orgId": currentUser?.data?.latestOrgId ?? 1,
            "hospitalId": currentUser?.data?.latestHospitalId ?? 1,
          },
          options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
        );

        if (res.data != null && res.data['data'] != null) {
          final data = res.data['data'];
          if (data['appointments'] is List) {
            for (final a in (data['appointments'] as List)) {
              loadedList.add({
                'id': a['id'],
                'appointmentDate': a['raw_date'] ?? a['appointment_date'],
                'startTime': a['start_time'],
                'endTime': a['end_time'],
                'duration': a['duration'],
                'doctorName': a['doctor_name'],
                'hospitalName': a['hospital_name'],
                'status': a['status'],
                'condition': a['condition'] ?? a['reason'],
                'reason': a['reason'] ?? a['condition'],
                'isTeleConsultation': a['is_tele_consultation'] ?? false,
                'meetingUrl': a['meeting_url'] ?? '',
                'patientName': currentUser?.data?.firstName != null
                    ? '${currentUser!.data!.firstName} ${currentUser.data!.lastName ?? ''}'.trim()
                    : 'Patient',
              });
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _allAppointments = loadedList;
        _isLoading = false;
      });
    }
  }

  DateTime? _parseFlexibleDate(dynamic rawDate, String dateStr) {
    if (rawDate != null) {
      if (rawDate is DateTime) return rawDate.toLocal();
      if (rawDate is String && rawDate.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(rawDate.trim());
        if (parsed != null) return parsed.toLocal();
      }
    }
    final s = dateStr.trim();
    if (s.isEmpty) return null;

    final parsedIso = DateTime.tryParse(s);
    if (parsedIso != null) return parsedIso.toLocal();

    try {
      const monthMap = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      };
      final clean = s.replaceAll(',', ' ').replaceAll('-', ' ').replaceAll('/', ' ');
      final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 3) {
        int? day, month, year;
        for (final p in parts) {
          final lower = p.toLowerCase();
          if (monthMap.containsKey(lower)) {
            month = monthMap[lower];
          } else if (int.tryParse(p) != null) {
            final val = int.parse(p);
            if (val > 1900 && val < 2100) {
              year = val;
            } else if (day == null && val >= 1 && val <= 31) {
              day = val;
            } else if (month == null && val >= 1 && val <= 12) {
              month = val;
            } else if (year == null) {
              year = val;
            }
          }
        }
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}

    return null;
  }

  DateTime? _parseAppointmentDateTime(Map<String, dynamic> a) {
    final parsedDate = _parseFlexibleDate(a['appointmentDate'], (a['appointmentDate'] ?? '').toString());
    if (parsedDate == null) return null;

    final startTimeStr = (a['startTime'] ?? '').toString().trim();
    if (startTimeStr.isNotEmpty) {
      if (startTimeStr.contains('T') || startTimeStr.contains('Z')) {
        final parsedTime = DateTime.tryParse(startTimeStr);
        if (parsedTime != null) {
          final local = parsedTime.toLocal();
          return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, local.hour, local.minute);
        }
      } else {
        try {
          final timeStr = startTimeStr.toUpperCase();
          final isPm = timeStr.contains('PM');
          final isAm = timeStr.contains('AM');
          final cleanTime = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
          final timeParts = cleanTime.split(':');
          if (timeParts.isNotEmpty) {
            int hour = int.tryParse(timeParts[0].trim()) ?? 0;
            int minute = timeParts.length > 1 ? (int.tryParse(timeParts[1].trim()) ?? 0) : 0;
            if (isPm && hour < 12) hour += 12;
            if (isAm && hour == 12) hour = 0;
            return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
          }
        } catch (_) {}
      }
    }

    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
  }

  String _formatAppointmentDateTime(Map<String, dynamic> apt) {
    final parsedDate = _parseFlexibleDate(apt['appointmentDate'], (apt['appointmentDate'] ?? '').toString());
    String formattedDate = '';

    if (parsedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final aptDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      if (aptDay == today) {
        formattedDate = 'Today';
      } else if (aptDay == today.add(const Duration(days: 1))) {
        formattedDate = 'Tomorrow';
      } else {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        formattedDate = '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
      }
    } else if (apt['appointmentDate'] != null) {
      formattedDate = apt['appointmentDate'].toString();
    }

    String displayTime = '';
    final rawStartTime = (apt['startTime'] ?? '').toString().trim();
    if (rawStartTime.isNotEmpty) {
      if (rawStartTime.contains('T') || rawStartTime.contains('Z')) {
        final parsedTime = DateTime.tryParse(rawStartTime);
        if (parsedTime != null) {
          final local = parsedTime.toLocal();
          int hour = local.hour;
          final min = local.minute.toString().padLeft(2, '0');
          final ampm = hour >= 12 ? 'PM' : 'AM';
          hour = hour % 12;
          if (hour == 0) hour = 12;
          displayTime = '$hour:$min $ampm';
        } else {
          displayTime = rawStartTime;
        }
      } else {
        displayTime = rawStartTime;
      }
    }

    final durationStr = (apt['duration'] ?? '15 mins').toString();

    final parts = <String>[];
    if (formattedDate.isNotEmpty) parts.add(formattedDate);
    if (displayTime.isNotEmpty) parts.add(displayTime);
    if (durationStr.isNotEmpty && durationStr != '0 mins') parts.add(durationStr);

    if (parts.isEmpty) return 'Scheduled';
    return parts.join(' • ');
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: now,
        end: now.add(const Duration(days: 7)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final rangeStr = "${DateFormat('MMM d').format(picked.start)} - ${DateFormat('MMM d').format(picked.end)}";
      setState(() {
        _customDateRange = picked;
        _selectedDateLabel = rangeStr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isTab = isTablet(context);
    final width = displayWidth(context);
    final primaryBlue = const Color(0xFF2563EB);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    // ─── 1. SEGREGATE UPCOMING VS COMPLETED ─────────────────────────────
    final List<Map<String, dynamic>> upcomingList = [];
    final List<Map<String, dynamic>> completedList = [];

    for (final a in _allAppointments) {
      final status = (a['status'] ?? '').toString().toLowerCase().trim();
      final aptDate = _parseAppointmentDateTime(a);

      if (status == 'completed') {
        completedList.add(a);
      } else if (status == 'cancelled') {
        // Excluded from active upcoming, can be shown in completed/history
        completedList.add(a);
      } else {
        if (aptDate != null) {
          final aptDay = DateTime(aptDate.year, aptDate.month, aptDate.day);
          if (aptDay.isBefore(todayStart)) {
            completedList.add(a);
          } else {
            upcomingList.add(a);
          }
        } else {
          upcomingList.add(a);
        }
      }
    }

    // Sort upcoming ascending (nearest first)
    upcomingList.sort((a, b) {
      final dtA = _parseAppointmentDateTime(a);
      final dtB = _parseAppointmentDateTime(b);
      if (dtA == null && dtB == null) return 0;
      if (dtA == null) return 1;
      if (dtB == null) return -1;
      return dtA.compareTo(dtB);
    });

    // Sort completed descending (newest first)
    completedList.sort((a, b) {
      final dtA = _parseAppointmentDateTime(a);
      final dtB = _parseAppointmentDateTime(b);
      if (dtA == null && dtB == null) return 0;
      if (dtA == null) return 1;
      if (dtB == null) return -1;
      return dtB.compareTo(dtA);
    });

    // ─── 2. APPLY SEARCH & FILTER TO CURRENT ACTIVE TAB ────────────────
    final targetList = _activeTab == "upcoming" ? upcomingList : completedList;
    final searchQuery = _searchController.text.trim().toLowerCase();

    final filteredList = targetList.where((a) {
      final docName = (a['doctorName'] ?? '').toString().toLowerCase();
      final patName = (a['patientName'] ?? '').toString().toLowerCase();
      final hospName = (a['hospitalName'] ?? '').toString().toLowerCase();
      final cond = (a['condition'] ?? a['reason'] ?? '').toString().toLowerCase();
      final status = (a['status'] ?? '').toString().toLowerCase();

      final matchesSearch = searchQuery.isEmpty ||
          docName.contains(searchQuery) ||
          patName.contains(searchQuery) ||
          hospName.contains(searchQuery) ||
          cond.contains(searchQuery);

      if (!matchesSearch) return false;

      if (_selectedStatus != "All Status") {
        if (!status.contains(_selectedStatus.toLowerCase())) {
          return false;
        }
      }

      final aptDate = _parseAppointmentDateTime(a);
      if (aptDate != null) {
        final aptDay = DateTime(aptDate.year, aptDate.month, aptDate.day);
        if (_selectedDateLabel == "Today") {
          if (aptDay != todayStart) return false;
        } else if (_selectedDateLabel == "Tomorrow") {
          if (aptDay != tomorrowStart) return false;
        } else if (_customDateRange != null && !_dateOptions.sublist(0, 3).contains(_selectedDateLabel)) {
          final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
          final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day);
          if (aptDay.isBefore(start) || aptDay.isAfter(end)) return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── 1. HEADER WITH BOOK BUTTON ──────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenHorizontalSpacePadding,
                isTab ? 20 : 14,
                screenHorizontalSpacePadding,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Appointments",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w700,
                            fontSize: isTab ? width * 0.028 : width * 0.058,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "Manage your upcoming visits & past consultations",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? width * 0.015 : width * 0.03,
                            color: isDark ? Colors.white38 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Book New Appointment Action Button (Solid Dashboard Primary Color)
                  Material(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        PatientBookAppointmentSheet.show(
                          context,
                          onAppointmentBooked: _loadAppointments,
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTab ? 16 : 14,
                          vertical: isTab ? 10 : 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 5),
                            Text(
                              "Book Visit",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.bold,
                                fontSize: isTab ? 14 : 12.5,
                                color: Colors.white,
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

            const SizedBox(height: 14),

            // ─── 2. UPCOMING VS COMPLETED SEGMENTED STAT TABS ──────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabStatCard(
                      title: "Upcoming",
                      count: "${upcomingList.length}",
                      subtitle: "Today & Future",
                      icon: Icons.hourglass_top_rounded,
                      iconColor: const Color(0xFF2563EB),
                      isActive: _activeTab == "upcoming",
                      onTap: () => setState(() => _activeTab = "upcoming"),
                      isDark: isDark,
                      isTab: isTab,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTabStatCard(
                      title: "Completed",
                      count: "${completedList.length}",
                      subtitle: "Past Consultations",
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF059669),
                      isActive: _activeTab == "completed",
                      onTap: () => setState(() => _activeTab = "completed"),
                      isDark: isDark,
                      isTab: isTab,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ─── 3. DATE SELECTOR & FILTER BAR ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: screenHorizontalSpacePadding,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    ..._dateOptions.map((opt) {
                      final isSelected = _selectedDateLabel == opt ||
                          (opt == "Date Range" && _customDateRange != null && !_dateOptions.sublist(0, 3).contains(_selectedDateLabel));
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (opt == "Date Range") {
                              _pickDateRange();
                            } else {
                              setState(() {
                                _customDateRange = null;
                                _selectedDateLabel = opt;
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF2563EB) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected && !isDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                opt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? Colors.white : const Color(0xFF2563EB))
                                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ─── 4. SEARCH & STATUS FILTER ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: "Search doctor, hospital, condition...",
                          hintStyle: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF2563EB)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Filter Dropdown
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        icon: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF2563EB)),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        items: _statusOptions.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ─── 5. APPOINTMENTS LIST VIEW ────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoadingShimmer(isTab)
                  : filteredList.isEmpty
                      ? _buildEmptyState(isDark)
                      : RefreshIndicator(
                          color: const Color(0xFF2563EB),
                          onRefresh: _loadAppointments,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              screenHorizontalSpacePadding,
                              4,
                              screenHorizontalSpacePadding,
                              24,
                            ),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final apt = filteredList[index];
                              final docName = (apt['doctorName'] ?? 'Doctor').toString();
                              final initials = docName.replaceFirst('Dr. ', '').trim().isNotEmpty
                                  ? (docName.replaceFirst('Dr. ', '').trim())[0].toUpperCase()
                                  : 'DR';
                              final hospitalName = (apt['hospitalName'] ?? apt['hospital_name'] ?? 'Healthcare Facility').toString();
                              final statusLabel = (apt['status'] ?? 'Scheduled').toString();
                              final isTele = apt['isTeleConsultation'] == true ||
                                  apt['is_tele_consultation'] == true ||
                                  apt['isTeleconsultation'] == true ||
                                  (apt['appointmentType'] ?? '').toString().toLowerCase().contains('video') ||
                                  (apt['appointmentType'] ?? '').toString().toLowerCase().contains('tele') ||
                                  (apt['appointment_type'] ?? '').toString().toLowerCase().contains('video') ||
                                  (apt['appointment_type'] ?? '').toString().toLowerCase().contains('tele') ||
                                  (apt['appointmentMode'] ?? '').toString().toLowerCase().contains('video') ||
                                  (apt['appointment_mode'] ?? '').toString().toLowerCase().contains('video') ||
                                  (apt['meetingUrl'] ?? apt['meeting_url'] ?? '').toString().trim().isNotEmpty;
                              final meetingUrl = (apt['meetingUrl'] ?? apt['meeting_url'] ?? '').toString();
                              final condition = (apt['condition'] ?? apt['reason'] ?? 'General Consultation').toString();
                              final patientName = (apt['patientName'] ?? apt['patient_name'] ?? 'Patient').toString();

                              final timeStr = _formatAppointmentDateTime(apt);

                              final isCompleted = statusLabel.toLowerCase().contains('complete');
                              final statusColor = isCompleted
                                  ? const Color(0xFF059669)
                                  : (statusLabel.toLowerCase().contains('cancel')
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF2563EB));

                              return DocAppointmentCard(
                                initials: initials,
                                name: docName,
                                subtitle: hospitalName,
                                description: condition.isNotEmpty ? condition : 'General Consultation',
                                timeOrDate: timeStr,
                                statusLabel: statusLabel,
                                statusColor: statusColor,
                                statusTextColor: Colors.white,
                                isTab: isTab,
                                isTeleConsultation: isTele,
                                onJoinCall: () {
                                  if (meetingUrl.isNotEmpty) {
                                    Utils.launchMeetingURL(
                                      meetingUrl,
                                      displayName: patientName,
                                      onLaunchFailure: (err) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(err)),
                                          );
                                        }
                                      },
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No meeting link available.')),
                                    );
                                  }
                                },
                                onTap: () {
                                  final currentUser = GlobalSession.instance.userNotifier.value;
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.doctorPatientProfileScreen,
                                    arguments: {
                                      'patientId': apt['patientUserId'] ?? currentUser?.data?.id ?? '',
                                      'appointmentId': apt['id']?.toString() ?? '',
                                      'hospitalId': apt['hospitalId']?.toString() ?? '1',
                                      'orgId': apt['organizationId']?.toString() ?? '1',
                                      'patientName': patientName,
                                      'initialStatus': statusLabel,
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabStatCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required bool isTab,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF0C4A6E) : const Color(0xFFE0F2FE))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isActive ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF2563EB)
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? (isDark ? Colors.white : const Color(0xFF0369A1))
                              : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
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

  Widget _buildLoadingShimmer(bool isTab) {
    return ListView.builder(
      padding: const EdgeInsets.all(screenHorizontalSpacePadding),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: BaseShimmer(
          child: Container(
            height: isTab ? 110 : 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _activeTab == "upcoming" ? Icons.event_available_rounded : Icons.history_rounded,
                size: 40,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _activeTab == "upcoming"
                  ? "No upcoming appointments"
                  : "No completed consultations",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeTab == "upcoming"
                  ? "Schedule a consultation with your doctor to stay on top of your health."
                  : "Your past appointments and medical history will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
            if (_activeTab == "upcoming") ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  PatientBookAppointmentSheet.show(
                    context,
                    onAppointmentBooked: _loadAppointments,
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Book Consultation", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
