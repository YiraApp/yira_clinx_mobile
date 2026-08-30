import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/app_route/app_routes.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/utils/utils.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../doctor/dashboard/widgets/doc_appointment_card.dart';
import '../../doctor/profile/widgets/profile_switcher_sheet.dart';
import '../../patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';
import '../appointments/patient_book_appointment_sheet.dart';
import '../doctors/widgets/scan_doctor_qr_sheet.dart';
import '../documents/patient_documents_screen.dart';
import '../widgets/patient_vitals_card.dart';
import '../widgets/update_vitals_sheet.dart';
import '../../../../core/services/notification_services/notification_services.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../../core/tour/patient_tour_controller.dart';
import '../../../../core/tour/patient_tour_mock_data.dart';

class PatientDashboardScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const PatientDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  Map<String, String> _vitalsData = {
    'bp': '--',
    'bpSystolic': '--',
    'bpDiastolic': '--',
    'pulse': '--',
    'temp': '--',
    'spO2': '--',
    'weight': '--',
    'height': '--',
    'lastUpdated': 'Not updated yet',
  };

  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadCachedVitals();
    NotificationService.instance.syncFcmTokenWithBackend();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PatientTourController().startDashboardTour(context: context);
    });
  }

  Future<void> _loadCachedVitals() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      if (userId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();

      final imgPath = prefs.getString('patient_profile_image_$userId');
      final savedStr = prefs.getString('patient_vitals_$userId');

      if (mounted) {
        setState(() {
          if (imgPath != null && imgPath.isNotEmpty && File(imgPath).existsSync()) {
            _profileImagePath = imgPath;
          }
          if (savedStr != null) {
            final Map<String, dynamic> decoded = jsonDecode(savedStr);
            decoded.forEach((key, value) {
              if (value != null && value.toString().trim().isNotEmpty) {
                _vitalsData[key] = value.toString();
              }
            });
          }
        });
      }
    } catch (_) {}
  }

  void _openUpdateVitalsSheet(BuildContext blocContext) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpdateVitalsSheet(
        currentVitals: _vitalsData,
        onSave: (updated) {
          setState(() {
            _vitalsData = updated;
          });
        },
      ),
    );
    if (result != null) {
      setState(() {
        _vitalsData = result;
      });

      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      final orgId = currentUser?.data?.latestOrgId ?? 1;
      final hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final token = currentUser?.data?.accessToken ?? '';

      // Cache locally immediately
      if (userId.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('patient_vitals_$userId', jsonEncode(result));

          // Append to vitals history
          final historyKey = 'patient_vitals_history_$userId';
          final historyStr = prefs.getString(historyKey);
          List<dynamic> historyList = [];
          if (historyStr != null) {
            try {
              historyList = jsonDecode(historyStr);
            } catch (_) {}
          }
          final entry = Map<String, dynamic>.from(result);
          entry['timestamp'] = DateTime.now().toIso8601String();
          historyList.add(entry);
          await prefs.setString(historyKey, jsonEncode(historyList));
        } catch (_) {}
      }

      if (userId.isNotEmpty) {
        try {
          debugPrint('[VITALS] Submitting vitals update for user: $userId');
          final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
            '/v1/api/auth/medical-records',
            data: {
              "patientId": userId,
              "bloodPressure": result['bp'],
              "heartRate": result['pulse'],
              "temperature": result['temp'],
              "weight": result['weight'],
              "height": result['height'],
              "organizationId": orgId,
              "hospitalId": hospitalId,
              "type": "Patient Self-Reported Vitals"
            },
            options: Options(
              headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
            ),
          );
          debugPrint('[VITALS] Submit response: ${response.statusCode}');
        } catch (e) {
          debugPrint('[VITALS] Submit error: $e');
        }

        // Always re-fetch vitals from server after update attempt
        if (mounted) {
          debugPrint('[VITALS] Refreshing patient overview to fetch updated vitals...');
          blocContext.read<PatientOverViewBloc>().add(LoadPatientData(
            userId,
            orgId: orgId.toString(),
            hospitalId: hospitalId.toString(),
          ));
        }
      }
    }
  }

  void _openProfileSwitcher() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSwitcherSheet(),
    );
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

  DateTime? _parseAppointmentDateTime(PatientAppointmentEntity a) {
    final parsedDate = _parseFlexibleDate(a.rawDate, a.appointmentDate);
    if (parsedDate == null) return null;

    if (a.startTime.isNotEmpty) {
      final rawStartTime = a.startTime.trim();
      if (rawStartTime.contains('T') || rawStartTime.contains('Z')) {
        final parsedTime = DateTime.tryParse(rawStartTime);
        if (parsedTime != null) {
          final local = parsedTime.toLocal();
          return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, local.hour, local.minute);
        }
      } else {
        try {
          final timeStr = rawStartTime.toUpperCase();
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

  String _formatAppointmentDateTime(PatientAppointmentEntity apt) {
    final parsedDate = _parseFlexibleDate(apt.rawDate, apt.appointmentDate);
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
    } else if (apt.appointmentDate.isNotEmpty) {
      formattedDate = apt.appointmentDate;
    }

    String displayTime = '';
    final rawStartTime = apt.startTime.trim();
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

    final parts = <String>[];
    if (formattedDate.isNotEmpty) {
      parts.add(formattedDate);
    }
    if (displayTime.isNotEmpty) {
      parts.add(displayTime);
    }
    if (apt.duration.isNotEmpty && apt.duration != '0 mins') {
      parts.add(apt.duration);
    }

    if (parts.isEmpty) {
      return 'Scheduled';
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);
    final adaptiveTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';
    final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';
    final firstName = currentUser?.data?.firstName ?? '';
    final lastName = currentUser?.data?.lastName ?? '';
    final patientName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Patient';

    return BlocProvider<PatientOverViewBloc>(
      create: (_) => sl<PatientOverViewBloc>()..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId)),
      child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
        builder: (context, state) {
          PatientOverViewEntity? overViewEntity;
          if (state is LoadPatientDataState) {
            overViewEntity = state.patientOverViewEntity;
          }

          final data = overViewEntity?.data;
          final latestVitals = data?.latestVitals;
          if (latestVitals != null) {
            final bpVal = latestVitals.bloodPressure?.value;
            final pulseVal = latestVitals.pulse?.value;
            final tempVal = latestVitals.temperature?.value;
            final spo2Val = latestVitals.spo2?.value;
            final weightVal = latestVitals.weight?.value;
            final heightVal = latestVitals.height?.value;

            bool isValidVital(String? val) =>
                val != null &&
                val.trim().isNotEmpty &&
                val.trim() != '--' &&
                val.trim().toLowerCase() != 'none' &&
                val.trim().toLowerCase() != 'null' &&
                val.trim().toLowerCase() != 'n/a';

            if (isValidVital(bpVal)) {
              _vitalsData['bp'] = bpVal!;
              if (bpVal.contains('/')) {
                _vitalsData['bpSystolic'] = bpVal.split('/').first.trim();
                _vitalsData['bpDiastolic'] = bpVal.split('/').last.trim();
              }
            }
            if (isValidVital(pulseVal)) _vitalsData['pulse'] = pulseVal!;
            if (isValidVital(tempVal)) _vitalsData['temp'] = tempVal!;
            if (isValidVital(spo2Val)) _vitalsData['spO2'] = spo2Val!;
            if (isValidVital(weightVal)) _vitalsData['weight'] = weightVal!;
            if (isValidVital(heightVal)) _vitalsData['height'] = heightVal!;

            final hasAny = [bpVal, pulseVal, tempVal, spo2Val, weightVal, heightVal].any(isValidVital);
            if (hasAny) {
              _vitalsData['lastUpdated'] = 'Latest Recorded';
            }
          }

          final List<PatientAppointmentEntity> allAppointments = data?.appointments ?? [];
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);

          // 1. Only include appointments for Today or in the Future (>= todayStart), excluding completed/cancelled
          final validUpcoming = allAppointments.where((a) {
            final status = a.status.toLowerCase().trim();
            if (status == 'completed' || status == 'cancelled') return false;

            final aptDateTime = _parseAppointmentDateTime(a);
            if (aptDateTime == null) return true;

            final aptDay = DateTime(aptDateTime.year, aptDateTime.month, aptDateTime.day);
            return !aptDay.isBefore(todayStart);
          }).toList();

          // 2. Sort ascending: nearest date & time first
          validUpcoming.sort((a, b) {
            final dtA = _parseAppointmentDateTime(a);
            final dtB = _parseAppointmentDateTime(b);
            if (dtA == null && dtB == null) return 0;
            if (dtA == null) return 1;
            if (dtB == null) return -1;
            return dtA.compareTo(dtB);
          });

          return ValueListenableBuilder<bool>(
            valueListenable: PatientTourController().isTourActiveNotifier,
            builder: (context, isTourActive, _) {
              final List<PatientAppointmentEntity> upcomingAppointments = isTourActive
                  ? PatientTourMockData.demoUpcomingAppointments
                  : validUpcoming.take(2).toList();

              final bool isLoading = state is LoadingPatientViewDetails && !isTourActive;

              return Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  automaticallyImplyLeading: false,
                  titleSpacing: screenHorizontalSpacePadding,
                  centerTitle: false,
                  title: Container(
                    key: PatientTourController().headerProfileKey,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SvgPicture.asset(
                            appLogo,
                            width: isTab ? 32 : 28,
                            height: isTab ? 32 : 28,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: GestureDetector(
                            onTap: _openProfileSwitcher,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    patientName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab ? 18.0 : 16.0,
                                      fontWeight: FontWeight.w700,
                                      color: adaptiveTextColor,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: adaptiveTextColor.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                IconButton(
                  tooltip: 'Recent Notifications',
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_none_rounded, color: primaryColor, size: 20),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.recentNotifications);
                  },
                ),
                IconButton(
                  tooltip: 'Scan Doctor QR',
                  icon: Icon(Icons.qr_code_scanner_rounded, color: primaryColor),
                  onPressed: () {
                    ScanDoctorQrSheet.show(context);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: screenHorizontalSpacePadding),
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onNavigateTab != null) {
                        widget.onNavigateTab!(3);
                      } else {
                        Navigator.pushNamed(context, AppRoutes.patientProfile);
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: (_profileImagePath != null && _profileImagePath!.isNotEmpty && File(_profileImagePath!).existsSync())
                            ? Image.file(
                                File(_profileImagePath!),
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: primaryColor.withValues(alpha: 0.15),
                                alignment: Alignment.center,
                                child: Text(
                                  patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                _loadCachedVitals();
                context.read<PatientOverViewBloc>().add(
                      LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId),
                    );
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: screenHorizontalSpacePadding,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Health Vitals (Single Card with Welcome Back matching provider layout)
                    Container(
                      key: PatientTourController().vitalsCardKey,
                      child: PatientVitalsCard(
                        vitals: isTourActive ? PatientTourMockData.demoVitals : _vitalsData,
                        isLoading: !isTourActive && (state is LoadingPatientViewDetails || state is PatientOverViewInitial),
                        onUpdateVitals: () => _openUpdateVitalsSheet(context),
                        patientName: patientName,
                        profileImagePath: _profileImagePath,
                        onProfileTap: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(3);
                          } else {
                            Navigator.pushNamed(context, AppRoutes.patientProfile);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Upcoming / Today Appointments (Show up to 2 appointments)
                    Container(
                      key: PatientTourController().upcomingAppointmentsKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Upcoming Appointments',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: isTab ? 18 : 15,
                                          fontWeight: FontWeight.bold,
                                          color: adaptiveTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (upcomingAppointments.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${upcomingAppointments.length}',
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  if (widget.onNavigateTab != null) {
                                    widget.onNavigateTab!(1);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (isLoading)
                            _buildAppointmentsShimmer(context, isDark)
                          else if (upcomingAppointments.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isTab ? 20 : 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.25)
                                        : const Color(0xFF64748B).withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.event_note_rounded,
                                          color: primaryColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'No upcoming appointments',
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isTab ? 15.5 : 14.5,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Connect with your verified doctors & specialists',
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize: 11.5,
                                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Divider(
                                    height: 1,
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                                            side: BorderSide(
                                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () => Navigator.pushNamed(context, AppRoutes.patientMyDoctors),
                                          icon: const Icon(Icons.people_outline_rounded, size: 15),
                                          label: const Text(
                                            'My Doctors',
                                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () {
                                            PatientBookAppointmentSheet.show(
                                              context,
                                              onAppointmentBooked: () {
                                                if (mounted) {
                                                  context.read<PatientOverViewBloc>().add(
                                                    LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId),
                                                  );
                                                }
                                              },
                                            );
                                          },
                                          icon: const Icon(Icons.calendar_today_rounded, size: 14),
                                          label: const Text(
                                            'Book Visit',
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: upcomingAppointments.map((apt) {
                                final docName = apt.doctorName.isNotEmpty
                                    ? apt.doctorName
                                    : 'Consulting Doctor';
                                final initials = docName.isNotEmpty
                                    ? (docName.startsWith('Dr. ')
                                        ? docName.replaceFirst('Dr. ', '').trim()
                                        : docName)[0]
                                        .toUpperCase()
                                    : 'DR';
                                final hospitalName = apt.hospitalName.isNotEmpty
                                    ? apt.hospitalName
                                    : 'Yira Healthcare';
                                final statusLabel = apt.status.isNotEmpty ? apt.status : 'Confirmed';
                                final timeStr = _formatAppointmentDateTime(apt);

                                final isDifferentPatient = apt.patientName.isNotEmpty &&
                                    apt.patientName != 'Patient' &&
                                    apt.patientName.toLowerCase() != patientName.toLowerCase();
                                final patientLabel = isDifferentPatient
                                    ? 'For: ${apt.patientName}'
                                    : (apt.isTeleConsultation ? 'Video Consultation' : 'In-Clinic Visit');

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: DocAppointmentCard(
                                    initials: initials,
                                    name: docName,
                                    subtitle: hospitalName,
                                    description: apt.condition.isNotEmpty
                                        ? apt.condition
                                        : (apt.reason.isNotEmpty
                                            ? apt.reason
                                            : 'General Consultation'),
                                    timeOrDate: timeStr,
                                    statusLabel: statusLabel,
                                    statusColor: const Color(0xFF10B981),
                                    statusTextColor: Colors.white,
                                    patientStatus: patientLabel,
                                    isTab: isTab,
                                    isTeleConsultation: apt.isTeleConsultation,
                                    onJoinCall: () {
                                      if (apt.meetingUrl.isNotEmpty) {
                                        Utils.launchMeetingURL(
                                          apt.meetingUrl,
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
                                          const SnackBar(
                                            content: Text('No meeting link available.'),
                                          ),
                                        );
                                      }
                                    },
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.doctorPatientProfileScreen,
                                        arguments: {
                                          'patientId': apt.patientUserId.isNotEmpty ? apt.patientUserId : userId,
                                          'appointmentId': apt.id,
                                          'hospitalId': hospitalId,
                                          'orgId': orgId,
                                          'patientName': apt.patientName.isNotEmpty ? apt.patientName : patientName,
                                          'initialStatus': apt.status,
                                          'initialTabIndex': 0,
                                        },
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Quick Services Grid
                    Container(
                      key: PatientTourController().quickServicesKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quick Services',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 18 : 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: adaptiveTextColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'All Features',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          GridView.count(
                            crossAxisCount: isTab ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isTab ? 1.3 : 1.18,
                            children: [
                              // 1. Book Appointment
                              _buildFeatureCard(
                                context: context,
                                title: 'Book Appointment',
                                subtitle: 'Consult verified doctors',
                                icon: Icons.calendar_month_rounded,
                                color: const Color(0xFFE11D48),
                                gradientColors: const [Color(0xFFE11D48), Color(0xFFBE123C)],
                                onTap: () {
                                  PatientBookAppointmentSheet.show(
                                    context,
                                    onAppointmentBooked: () {
                                      if (mounted) {
                                        context.read<PatientOverViewBloc>().add(
                                          LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),

                              // 2. Medical Records
                              _buildFeatureCard(
                                context: context,
                                title: 'Medical Records',
                                subtitle: 'Lab reports & files',
                                icon: Icons.folder_shared_rounded,
                                color: const Color(0xFF0284C7),
                                gradientColors: const [Color(0xFF0284C7), Color(0xFF0369A1)],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PatientDocumentsScreen(),
                                    ),
                                  );
                                },
                              ),

                              // 3. My Vitals
                              _buildFeatureCard(
                                context: context,
                                title: 'My Vitals',
                                subtitle: 'Graphs & health trends',
                                icon: Icons.monitor_heart_rounded,
                                color: const Color(0xFF10B981),
                                gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.patientVitalsTracking,
                                ),
                              ),

                              // 4. My Doctors
                              _buildFeatureCard(
                                context: context,
                                title: 'My Doctors',
                                subtitle: 'Connected specialists',
                                icon: Icons.badge_rounded,
                                color: const Color(0xFF0D9488),
                                gradientColors: const [Color(0xFF0D9488), Color(0xFF0F766E)],
                                onTap: () => Navigator.pushNamed(context, AppRoutes.patientMyDoctors),
                              ),

                              // 5. My Family
                              _buildFeatureCard(
                                context: context,
                                title: 'My Family',
                                subtitle: 'Members & Profiles',
                                icon: Icons.family_restroom_rounded,
                                color: const Color(0xFF6366F1),
                                gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.patientMyFamily,
                                ),
                              ),

                              // 6. Doctor Suggestions
                              _buildFeatureCard(
                                context: context,
                                title: 'Doctor Suggestions',
                                subtitle: 'Medical advice & tips',
                                icon: Icons.lightbulb_rounded,
                                color: const Color(0xFF8B5CF6),
                                gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.patientDoctorSuggestions,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  ),
);
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF64748B).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          gradientColors[0].withValues(alpha: isDark ? 0.25 : 0.15),
                          gradientColors[1].withValues(alpha: isDark ? 0.15 : 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                      ),
                    ),
                    child: Icon(icon, color: color, size: isTab ? 24 : 20),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 14 : 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsShimmer(BuildContext context, bool isDark) {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 1,
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: BaseShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar + Name / Hospital + Status Badge
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 130,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 90,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 65,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
                const SizedBox(height: 10),
                // Bottom row: Date/Time badge + Visit mode badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      width: 85,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
