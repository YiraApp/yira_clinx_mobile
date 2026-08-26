import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../config/app_route/app_routes.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/appointments/appointment_entity.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../appointments/appointment_bloc/appointment_bloc.dart';
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

  void _openProfileSwitcher() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSwitcherSheet(),
    );
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

    return MultiBlocProvider(
      providers: [
        BlocProvider<PatientOverViewBloc>(
          create: (_) => sl<PatientOverViewBloc>()..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId)),
        ),
        BlocProvider<AppointmentBloc>(
          create: (_) => sl<AppointmentBloc>()..add(LoadAppointmentsEvent()),
        ),
      ],
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
                        style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<PatientOverViewBloc>().add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId));
                context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Health Vitals (Single Card with Welcome Back matching provider layout)
                    PatientVitalsCard(
                      vitals: _vitalsData,
                      onUpdateVitals: _openUpdateVitalsSheet,
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

                    BlocBuilder<AppointmentBloc, AppointmentState>(
                      builder: (context, aptState) {
                        if (aptState is AppointmentLoading) {
                          return _buildAppointmentsShimmer(context, isDark);
                        }

                        List<Appointment> upcomingAppointments = [];
                        if (aptState is AppointmentLoaded) {
                          upcomingAppointments = aptState.appointments
                              .where((a) => (a.statusRaw.toLowerCase() != 'completed' && a.statusRaw.toLowerCase() != 'cancelled'))
                              .take(2)
                              .toList();
                        }

                        if (upcomingAppointments.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
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
                                  child: Icon(Icons.event_available_rounded, color: primaryColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'No appointments scheduled today',
                                        style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 13, color: adaptiveTextColor),
                                      ),
                                      Text(
                                        'Book a consultation with your doctor',
                                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    if (widget.onNavigateTab != null) {
                                      widget.onNavigateTab!(1);
                                    }
                                  },
                                  child: const Text('Book', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: upcomingAppointments.map((apt) {
                            final docName = apt.doctorName ?? 'Consulting Doctor';
                            final initials = docName.isNotEmpty ? docName[0].toUpperCase() : 'DR';
                            final hospitalName = (apt.hospitalName != null && apt.hospitalName!.isNotEmpty)
                                ? apt.hospitalName!
                                : ((apt.hospitalId != null && apt.hospitalId == 19) ? 'Yira Hospitals' : 'Yira Clinx Medical Center');
                            final statusLabel = apt.statusRaw.isNotEmpty ? apt.statusRaw : 'Confirmed';

                            return DocAppointmentCard(
                              initials: initials,
                              name: docName,
                              subtitle: hospitalName,
                              description: apt.category.isNotEmpty ? apt.category : 'General Consultation',
                              timeOrDate: '${apt.time} • ${apt.duration}',
                              statusLabel: statusLabel,
                              statusColor: const Color(0xFF059669),
                              statusTextColor: Colors.white,
                              isTab: isTab,
                              isTeleConsultation: apt.type == AppointmentType.videoCall,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.doctorPatientProfileScreen,
                                  arguments: {
                                    'patientId': apt.patientUserId ?? userId,
                                    'appointmentId': apt.id,
                                    'hospitalId': apt.hospitalId?.toString() ?? '1',
                                    'orgId': apt.orgId?.toString() ?? '1',
                                    'patientName': apt.patientName.isNotEmpty ? apt.patientName : patientName,
                                    'initialStatus': apt.statusRaw,
                                    'initialTabIndex': 0,
                                  },
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
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
                          onTap: () => Navigator.pushNamed(context, AppRoutes.userPrescriptionManagement),
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
                              MaterialPageRoute(builder: (_) => const PatientDocumentsScreen()),
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
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
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
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? Colors.white38 : Colors.grey[400]),
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
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
          ),
          child: BaseShimmer(
            child: Row(
              children: [
                Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 140, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
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
