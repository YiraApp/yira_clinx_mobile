import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import '../../../../core/app_navigation_drawer/app_navigation_drawer.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../doctor/profile/widgets/profile_switcher_sheet.dart';
import '../../patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';
import '../widgets/patient_appointment_card.dart';
import '../widgets/patient_vitals_grid.dart';
import '../widgets/update_vitals_sheet.dart';
import '../../upload_documnets/uploaded_bloc/uploaded_bloc.dart';
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

  void _openUpdateVitalsSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdateVitalsSheet(
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
    }
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
    final patientName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Ch. Raja Vardan';

    return MultiBlocProvider(
      providers: [
        BlocProvider<PatientOverViewBloc>(
          create: (_) => sl<PatientOverViewBloc>()..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId)),
        ),
        BlocProvider<UploadedBloc>(
          create: (_) => sl<UploadedBloc>()..add(FetchUploadedRecords(patientId: userId, limit: 2)),
        ),
      ],
      child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
        builder: (context, state) {
          PatientOverViewEntity? overViewEntity;
          if (state is LoadPatientDataState) {
            overViewEntity = state.patientOverViewEntity;
          }

          final isLoading = state is LoadingPatientViewDetails || state is PatientOverViewInitial || overViewEntity == null;
          final data = overViewEntity?.data;
          DateTime? parseDate(String? dStr) {
            if (dStr == null || dStr.trim().isEmpty || dStr.trim().toLowerCase() == 'null' || dStr.trim().toLowerCase() == 'none') return null;
            final dt = DateTime.tryParse(dStr);
            if (dt != null) return dt;
            final parts = dStr.replaceAll(',', '').trim().split(RegExp(r'\s+'));
            if (parts.length >= 3) {
              int? day = int.tryParse(parts[0]);
              int? year = int.tryParse(parts[2]);
              String monthStr = parts[1].toLowerCase();
              if (day == null) {
                monthStr = parts[0].toLowerCase();
                day = int.tryParse(parts[1]);
                year = int.tryParse(parts[2]);
              }
              if (day != null && year != null) {
                const months = {'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12};
                for (final entry in months.entries) {
                  if (monthStr.startsWith(entry.key)) return DateTime(year, entry.value, day);
                }
              }
            }
            return null;
          }

          bool isUpcomingDate(String? dStr) {
            if (dStr == null || dStr.isEmpty) return false;
            final parsed = parseDate(dStr);
            if (parsed == null) return true;
            final now = DateTime.now();
            final todayMidnight = DateTime(now.year, now.month, now.day);
            return !DateTime(parsed.year, parsed.month, parsed.day).isBefore(todayMidnight);
          }

          NextAppointmentEntity? nextAppointment;
          if (data?.nextAppointment != null) {
            final dateCandidate = data!.nextAppointment!.formattedDate ?? data.nextAppointment!.appointmentDate;
            if (isUpcomingDate(dateCandidate)) {
              nextAppointment = data.nextAppointment;
            }
          }

          if (nextAppointment == null && data?.upcomingAppointments != null && data!.upcomingAppointments!.isNotEmpty) {
            try {
              final candidate = data.upcomingAppointments!.firstWhere(
                (u) => isUpcomingDate(u.formattedDate ?? u.appointmentDate),
              );
              nextAppointment = candidate;
            } catch (_) {}
          }

          if (nextAppointment == null && data?.appointments != null && data!.appointments!.isNotEmpty) {
            try {
              final appt = data.appointments!.firstWhere(
                (a) => isUpcomingDate(a.appointmentDate),
              );
              nextAppointment = NextAppointmentEntity(
                id: appt.id,
                appointmentId: appt.id,
                doctorName: appt.doctorName,
                doctorId: appt.doctorId,
                doctorSpecialty: appt.reason.isNotEmpty ? appt.reason : appt.appointmentType,
                hospitalName: appt.hospitalName,
                appointmentDate: appt.appointmentDate,
                formattedDate: appt.appointmentDate,
                startTime: appt.startTime,
                formattedTime: appt.startTime,
                consultationType: appt.appointmentType,
                isTeleconsultation: appt.isTeleConsultation,
                reason: appt.reason,
                status: appt.status,
                meetingUrl: appt.meetingUrl,
              );
            } catch (_) {}
          }

          final nextAppointmentDate = nextAppointment?.formattedDate ?? nextAppointment?.appointmentDate ?? data?.visitHistory?.nextScheduledAppointment;
          final hasNextAppointment = nextAppointment != null && isUpcomingDate(nextAppointmentDate);



          final latestVitals = data?.latestVitals;
          if (latestVitals != null) {
            final bpVal = latestVitals.bloodPressure?.value;
            final pulseVal = latestVitals.pulse?.value;
            final tempVal = latestVitals.temperature?.value;
            final spo2Val = latestVitals.spo2?.value;
            final weightVal = latestVitals.weight?.value;
            final heightVal = latestVitals.height?.value;

            bool isValidVital(String? val) => val != null && val.trim().isNotEmpty && val.trim().toLowerCase() != 'none' && val.trim().toLowerCase() != 'null' && val.trim().toLowerCase() != 'n/a';

            if (isValidVital(bpVal)) _vitalsData['bp'] = bpVal!;
            if (isValidVital(pulseVal)) _vitalsData['pulse'] = pulseVal!;
            if (isValidVital(tempVal)) _vitalsData['temp'] = tempVal!;
            if (isValidVital(spo2Val)) _vitalsData['spO2'] = spo2Val!;
            if (isValidVital(weightVal)) _vitalsData['weight'] = weightVal!;
            if (isValidVital(heightVal)) _vitalsData['height'] = heightVal!;
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: const AppNavigationDrawer(),
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
                      onTap: () => ProfileSwitcherSheet.show(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  patientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTab ? 16 : 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: adaptiveTextColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: adaptiveTextColor.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: "Notifications",
                  icon: Icon(
                    Icons.notifications_none_outlined,
                    color: adaptiveTextColor,
                    size: isTab ? 24 : 22,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.notificationSettingsScreen);
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
                      width: isTab ? 38 : 34,
                      height: isTab ? 38 : 34,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(patientName),
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 14 : 12,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
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
                context.read<PatientOverViewBloc>().add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId));
                context.read<UploadedBloc>().add(FetchUploadedRecords(patientId: userId, limit: 2));
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // 1. Health Vitals Overview Grid (First)
                    isLoading
                        ? _buildVitalsGridShimmer(context, isDark)
                        : PatientVitalsGrid(
                            vitals: _vitalsData,
                            onUpdateVitals: _openUpdateVitalsSheet,
                          ),
                    const SizedBox(height: 24),

                    // 2. Upcoming / New Appointment Card (Below Vitals if exists)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      child: isLoading
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNextAppointmentShimmer(context, isDark),
                                const SizedBox(height: 24),
                              ],
                            )
                          : hasNextAppointment
                              ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Next Appointment',
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
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
                                PatientAppointmentCard(
                                  doctorName: nextAppointment?.doctorName ?? 'Attending Physician',
                                  specialty: nextAppointment?.doctorSpecialty ?? nextAppointment?.reason ?? nextAppointment?.consultationType ?? data?.summary ?? 'General Practitioner',
                                  hospitalName: nextAppointment?.hospitalName ?? 'ClinicX Health Center',
                                  date: nextAppointment?.formattedDate ?? nextAppointmentDate ?? 'Scheduled Visit',
                                  time: nextAppointment?.formattedTime ?? nextAppointment?.startTime ?? 'Scheduled Slot',
                                  status: nextAppointment?.status ?? 'Scheduled',
                                  isTeleconsultation: nextAppointment?.isTeleconsultation ?? false,
                                  meetingUrl: nextAppointment?.meetingUrl,
                                  onTap: () {
                                    if (widget.onNavigateTab != null) {
                                      widget.onNavigateTab!(1);
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // 3. Recent Clinical Records Section (Below Next Appointment)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Clinical Records',
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
                              widget.onNavigateTab!(2);
                            }
                          },
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text(
                            'View Vault',
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

                    BlocBuilder<UploadedBloc, UploadedBlocState>(
                      builder: (context, state) {
                        if (state.status == UploadedStatus.initial || state.status == UploadedStatus.loading) {
                          return _buildRecentRecordsShimmer(context, isDark);
                        }
                        final docs = state.allRecords.take(2).toList();
                        if (docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No recent clinical documents available',
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: Colors.grey[500]),
                            ),
                          );
                        }

                        return Column(
                          children: docs.map((doc) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildClinicalRecordItem(
                                context: context,
                                title: doc.fileName,
                                date: '${doc.uploadDate.day}/${doc.uploadDate.month}/${doc.uploadDate.year}',
                                hospital: '🏥 Yira Health Network',
                                type: doc.category.isNotEmpty ? doc.category : 'Medical Report',
                                typeColor: doc.category.toLowerCase().contains('lab') ? Colors.purple : Colors.blue,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // 4. Quick Action Shortcuts Grid (At Last)
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: adaptiveTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionShortcut(
                                context: context,
                                title: 'Book Visit',
                                icon: Icons.calendar_month_rounded,
                                color: Colors.blue,
                                onTap: () {
                                  if (widget.onNavigateTab != null) {
                                    widget.onNavigateTab!(1);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionShortcut(
                                context: context,
                                title: 'My Records',
                                icon: Icons.folder_shared_rounded,
                                color: Colors.teal,
                                onTap: () {
                                  if (widget.onNavigateTab != null) {
                                    widget.onNavigateTab!(2);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionShortcut(
                                context: context,
                                title: 'Log Vitals',
                                icon: Icons.edit_note_rounded,
                                color: const Color(0xFFE11D48),
                                onTap: _openUpdateVitalsSheet,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionShortcut(
                                context: context,
                                title: 'My Profile',
                                icon: Icons.person_pin_rounded,
                                color: Colors.indigo,
                                onTap: () {
                                  if (widget.onNavigateTab != null) {
                                    widget.onNavigateTab!(3);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  },
),
);
  }

  Widget _buildActionShortcut({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalRecordItem({
    required BuildContext context,
    required String title,
    required String date,
    required String hospital,
    required String type,
    required Color typeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.description_rounded, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$hospital • $date',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildNextAppointmentShimmer(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
      ),
      child: BaseShimmer(
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 140, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(width: 100, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: 160, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsShimmer(BuildContext context, bool isDark) {
    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 3 ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
            ),
            child: BaseShimmer(
              child: Column(
                children: [
                  Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(height: 8),
                  Container(width: 45, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVitalsGridShimmer(BuildContext context, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
          ),
          child: BaseShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    Container(width: 40, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
                Container(width: 70, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                Container(width: 90, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentRecordsShimmer(BuildContext context, bool isDark) {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
          ),
          child: BaseShimmer(
            child: Row(
              children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 160, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(width: 100, height: 11, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
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
