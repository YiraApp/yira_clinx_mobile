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
import '../../../../core/services/notification_services/notification_services.dart';
import '../../../../core/tour/patient_tour_controller.dart';
import '../documents/patient_documents_screen.dart';
import '../offers/widgets/offer_banner_carousel.dart';
import '../offers/widgets/offer_popup_ad_dialog.dart';
import 'widgets/animated_service_icon.dart';
import '../../../../core/widgets/notification_badge_icon.dart';
import '../../../../core/services/notification_services/notification_badge_service.dart';

class PatientDashboardScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const PatientDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  String? _profileImagePath;
  final GlobalKey<OfferBannerCarouselState> _offerCarouselKey = GlobalKey<OfferBannerCarouselState>();

  @override
  void initState() {
    super.initState();
    _loadCachedProfileImage();
    NotificationService.instance.syncFcmTokenWithBackend();
    NotificationBadgeService.instance.syncUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PatientTourController().startDashboardTour(context: context);
      OfferPopupAdDialog.showIfAvailable(context);
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
                    const NotificationBadgeIcon(
                      showCapsule: true,
                      size: 20,
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
                _offerCarouselKey.currentState?.refresh();
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
                    // Offer Banners Carousel (only occupies space if active banners exist)
                    OfferBannerCarousel(
                      key: _offerCarouselKey,
                      organizationId: orgId,
                    ),

                    // Quick Services Section
                    Container(
                      key: PatientTourController().quickServicesKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Featured Top Card: Book Appointment
                          _buildAppointmentCard(
                            context: context,
                            primaryColor: primaryColor,
                            isDark: isDark,
                            isTab: isTab,
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
                          const SizedBox(height: 12),

                          // 2-5: The 2x2 Grid for 4 Core Services
                          GridView.count(
                            crossAxisCount: isTab ? 4 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isTab ? 1.35 : 1.20,
                            children: [
                              // 2. Medical Records
                              _buildServiceCard(
                                context: context,
                                title: 'Medical Records',
                                subtitle: 'Lab reports & files',
                                icon: Icons.folder_shared_rounded,
                                animationType: ServiceAnimationType.float,
                                staggerDelayMs: 150,
                                primaryColor: primaryColor,
                                isDark: isDark,
                                isTab: isTab,
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
                              _buildServiceCard(
                                context: context,
                                title: 'My Vitals',
                                subtitle: 'Graphs & health trends',
                                icon: Icons.monitor_heart_rounded,
                                animationType: ServiceAnimationType.heartbeat,
                                staggerDelayMs: 300,
                                primaryColor: primaryColor,
                                isDark: isDark,
                                isTab: isTab,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.patientVitalsTracking,
                                ),
                              ),

                              // 4. My Family
                              _buildServiceCard(
                                context: context,
                                title: 'My Family',
                                subtitle: 'Members & profiles',
                                icon: Icons.family_restroom_rounded,
                                animationType: ServiceAnimationType.bob,
                                staggerDelayMs: 450,
                                primaryColor: primaryColor,
                                isDark: isDark,
                                isTab: isTab,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.patientMyFamily,
                                ),
                              ),

                              // 5. Doctor Suggestions
                              _buildServiceCard(
                                context: context,
                                title: 'Doctor Suggestions',
                                subtitle: 'Medical advice & tips',
                                icon: Icons.lightbulb_rounded,
                                animationType: ServiceAnimationType.glow,
                                staggerDelayMs: 600,
                                primaryColor: primaryColor,
                                isDark: isDark,
                                isTab: isTab,
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
      ),
    );
  }

  Widget _buildAppointmentCard({
    required BuildContext context,
    required Color primaryColor,
    required bool isDark,
    required bool isTab,
    required VoidCallback onTap,
  }) {
    return _PressableCard(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTab ? 20 : 16,
          vertical: isTab ? 16 : 14,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Solid Medical Calendar Icon Container (No Gradients)
            Container(
              width: isTab ? 52 : 46,
              height: isTab ? 52 : 46,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: isTab ? 24 : 21,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Content & Value Proposition
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 16 : 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Consult verified doctors • Video & In-Clinic',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 12 : 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Clean Solid Arrow Accessory
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ServiceAnimationType animationType,
    int staggerDelayMs = 0,
    required Color primaryColor,
    required bool isDark,
    required bool isTab,
    required VoidCallback onTap,
  }) {
    return _PressableCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.20)
                  : const Color(0xFF64748B).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
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
                AnimatedServiceIcon(
                  icon: icon,
                  animationType: animationType,
                  staggerDelayMs: staggerDelayMs,
                  size: isTab ? 46 : 42,
                  color: primaryColor,
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 14 : 13,
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
                    fontSize: isTab ? 11 : 10,
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
    );
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
