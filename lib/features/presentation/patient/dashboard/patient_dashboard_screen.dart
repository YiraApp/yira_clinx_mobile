import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/app_route/app_routes.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../di/dependency_injection.dart';
import '../../doctor/profile/widgets/profile_switcher_sheet.dart';
import '../../patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';
import '../appointments/patient_book_appointment_sheet.dart';
import '../doctors/widgets/scan_doctor_qr_sheet.dart';
import '../documents/patient_documents_screen.dart';
import '../../../../core/services/notification_services/notification_services.dart';
import '../../../../core/tour/patient_tour_controller.dart';

class PatientDashboardScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const PatientDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadCachedProfileImage();
    NotificationService.instance.syncFcmTokenWithBackend();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PatientTourController().startDashboardTour(context: context);
    });
  }

  Future<void> _loadCachedProfileImage() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      if (userId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();

      final imgPath = prefs.getString('patient_profile_image_$userId');

      if (mounted) {
        setState(() {
          if (imgPath != null && imgPath.isNotEmpty && File(imgPath).existsSync()) {
            _profileImagePath = imgPath;
          }
        });
      }
    } catch (_) {}
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

    return BlocProvider<PatientOverViewBloc>(
      create: (_) => sl<PatientOverViewBloc>()..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId)),
      child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
        builder: (context, state) {
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
                _loadCachedProfileImage();
                context.read<PatientOverViewBloc>().add(
                      LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId),
                    );
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: screenHorizontalSpacePadding,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Services Grid
                    Container(
                      key: PatientTourController().quickServicesKey,
                      child: GridView.count(
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
}
