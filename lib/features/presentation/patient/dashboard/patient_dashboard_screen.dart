import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../documents/patient_documents_screen.dart';
import '../widgets/patient_vitals_card.dart';
import '../widgets/update_vitals_sheet.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';

class PatientDashboardScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const PatientDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  Map<String, String> _vitalsData = {
    'bp': '120/80',
    'bpSystolic': '120',
    'bpDiastolic': '80',
    'pulse': '72',
    'temp': '98.6',
    'spO2': '98',
    'weight': '68',
    'height': '172',
    'lastUpdated': 'Today',
  };

  String _getInitials(String name) {
    final clean = name.trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'PT';
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].length > 1 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
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
                val.trim().toLowerCase() != 'none' &&
                val.trim().toLowerCase() != 'null' &&
                val.trim().toLowerCase() != 'n/a';

            _vitalsData['bp'] = isValidVital(bpVal) ? bpVal! : (_vitalsData['bp'] != null && _vitalsData['bp'] != '--' ? _vitalsData['bp']! : '120/80');
            _vitalsData['pulse'] = isValidVital(pulseVal) ? pulseVal! : (_vitalsData['pulse'] != null && _vitalsData['pulse'] != '--' ? _vitalsData['pulse']! : '72');
            _vitalsData['temp'] = isValidVital(tempVal) ? tempVal! : (_vitalsData['temp'] != null && _vitalsData['temp'] != '--' ? _vitalsData['temp']! : '98.6');
            _vitalsData['spO2'] = isValidVital(spo2Val) ? spo2Val! : (_vitalsData['spO2'] != null && _vitalsData['spO2'] != '--' ? _vitalsData['spO2']! : '98');
            _vitalsData['weight'] = isValidVital(weightVal) ? weightVal! : (_vitalsData['weight'] != null && _vitalsData['weight'] != '--' ? _vitalsData['weight']! : '68');
            _vitalsData['height'] = isValidVital(heightVal) ? heightVal! : (_vitalsData['height'] != null && _vitalsData['height'] != '--' ? _vitalsData['height']! : '172');
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

          final List<PatientAppointmentEntity> upcomingAppointments = validUpcoming.take(2).toList();

          final bool isLoading = state is LoadingPatientViewDetails;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              titleSpacing: screenHorizontalSpacePadding,
              centerTitle: false,
              title: Row(
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
              actions: [
                IconButton(
                  tooltip: 'Switch Family Member',
                  icon: Icon(Icons.people_outline_rounded, color: primaryColor),
                  onPressed: _openProfileSwitcher,
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
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: primaryColor.withValues(alpha: 0.15),
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
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
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
                    PatientVitalsCard(
                      vitals: _vitalsData,
                      isLoading: state is LoadingPatientViewDetails || state is PatientOverViewInitial,
                      onUpdateVitals: () => _openUpdateVitalsSheet(context),
                      patientName: patientName,
                    ),
                    const SizedBox(height: 20),

                    // 2. Upcoming / Today Appointments (Show up to 2 appointments)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Appointments',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: adaptiveTextColor,
                          ),
                        ),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_available_rounded,
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
                                    'No appointments scheduled today',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: adaptiveTextColor,
                                    ),
                                  ),
                                  Text(
                                    'Book a consultation with your doctor',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                if (widget.onNavigateTab != null) {
                                  widget.onNavigateTab!(1);
                                }
                              },
                              child: const Text(
                                'Book',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
                              : 'Yira Hospitals';
                          final statusLabel = apt.status.isNotEmpty ? apt.status : 'Scheduled';
                          final timeStr = _formatAppointmentDateTime(apt);

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
                              statusColor: const Color(0xFF059669),
                              statusTextColor: Colors.white,
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
                                    'patientId': userId,
                                    'appointmentId': apt.id,
                                    'hospitalId': hospitalId,
                                    'orgId': orgId,
                                    'patientName': patientName,
                                    'initialStatus': apt.status,
                                    'initialTabIndex': 0,
                                  },
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),

                    // 3. Four Core Feature Navigation Cards
                    Text(
                      'Medical Services & Records',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: adaptiveTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: isTab ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: isTab ? 1.3 : 1.15,
                      children: [
                        _buildFeatureCard(
                          context: context,
                          title: 'Prescriptions',
                          subtitle: 'Active medicines & rx',
                          icon: Icons.medication_rounded,
                          color: const Color(0xFF8B5CF6),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.userPrescriptionManagement,
                          ),
                        ),
                        _buildFeatureCard(
                          context: context,
                          title: 'My Health Checkups',
                          subtitle: 'Visits & clinic summaries',
                          icon: Icons.health_and_safety_rounded,
                          color: const Color(0xFF059669),
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(1);
                            }
                          },
                        ),
                        _buildFeatureCard(
                          context: context,
                          title: 'My Records & Reports',
                          subtitle: 'Lab tests, scans & PDFs',
                          icon: Icons.folder_shared_rounded,
                          color: const Color(0xFF0284C7),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PatientDocumentsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildFeatureCard(
                          context: context,
                          title: 'Appointments View',
                          subtitle: 'Full visit schedule',
                          icon: Icons.calendar_month_rounded,
                          color: const Color(0xFFEA580C),
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(1);
                            }
                          },
                        ),
                        _buildFeatureCard(
                          context: context,
                          title: 'My Doctors',
                          subtitle: 'Connected specialists & QR',
                          icon: Icons.badge_rounded,
                          color: const Color(0xFF0D9488),
                          onTap: () => Navigator.pushNamed(context, AppRoutes.patientMyDoctors),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
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
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: isTab ? 26 : 22),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark ? Colors.white38 : Colors.grey[400],
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
                    fontSize: isTab ? 15 : 13,
                    fontWeight: FontWeight.bold,
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
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsShimmer(BuildContext context, bool isDark) {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
            ),
          ),
          child: BaseShimmer(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 100,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
