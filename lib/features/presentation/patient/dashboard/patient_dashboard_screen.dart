import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
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
import '../../../../core/tour/patient_tour_mock_data.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../documents/patient_documents_screen.dart';
import '../offers/widgets/offer_banner_carousel.dart';
import '../offers/widgets/offer_popup_ad_dialog.dart';
import '../../../../core/widgets/notification_badge_icon.dart';
import '../../../../core/services/notification_services/notification_badge_service.dart';
import '../../../../core/services/fitness/fitness_sync_service.dart';

class PatientDashboardScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const PatientDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> with WidgetsBindingObserver {
  String? _profileImagePath;
  final GlobalKey<OfferBannerCarouselState> _offerCarouselKey = GlobalKey<OfferBannerCarouselState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCachedProfileImage();
    NotificationService.instance.syncFcmTokenWithBackend();
    NotificationBadgeService.instance.syncUnreadCount();
    FitnessSyncService.instance.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PatientTourController().startDashboardTour(context: context);
      OfferPopupAdDialog.showIfAvailable(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FitnessSyncService.instance.syncNow(silent: true);
    }
  }

  Future<void> _loadCachedProfileImage() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      if (userId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();

      final localPath = prefs.getString('patient_profile_image_$userId');
      final networkUrl = prefs.getString('patient_profile_network_image_$userId') ??
          currentUser?.data?.imagePath ??
          (currentUser?.data?.profiles?.isNotEmpty == true ? currentUser!.data!.profiles!.first.imagePath : null);

      if (mounted) {
        setState(() {
          if (localPath != null && localPath.isNotEmpty && File(localPath).existsSync()) {
            _profileImagePath = localPath;
          } else if (networkUrl != null && networkUrl.isNotEmpty) {
            _profileImagePath = networkUrl;
          }
        });
      }
    } catch (_) {}
  }

  Widget _buildDashboardAvatar(String? imgPath, String patientName, Color primaryColor) {
    if (imgPath != null && imgPath.isNotEmpty) {
      if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: imgPath,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: primaryColor.withValues(alpha: 0.1),
            alignment: Alignment.center,
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: primaryColor),
            ),
          ),
          errorWidget: (context, url, error) => _buildDashboardInitials(patientName, primaryColor),
        );
      } else if (imgPath.startsWith('data:image')) {
        try {
          final commaIdx = imgPath.indexOf(',');
          final base64Str = commaIdx != -1 ? imgPath.substring(commaIdx + 1) : imgPath;
          return Image.memory(
            base64Decode(base64Str),
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDashboardInitials(patientName, primaryColor),
          );
        } catch (_) {}
      } else if (File(imgPath).existsSync()) {
        return Image.file(
          File(imgPath),
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDashboardInitials(patientName, primaryColor),
        );
      }
    }
    return _buildDashboardInitials(patientName, primaryColor);
  }

  Widget _buildDashboardInitials(String patientName, Color primaryColor) {
    return Container(
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
    );
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
    if (rawDate is DateTime) return rawDate.toLocal();
    final s = (rawDate?.toString() ?? dateStr).trim();
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
            } else {
              year ??= val;
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

  void _navigateToAppointmentDetails(
    BuildContext context,
    PatientAppointmentEntity apt,
    String patientName,
    String userId,
    String orgId,
    String hospitalId,
  ) {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);
    final adaptiveTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return ValueListenableBuilder<LoginEntity?>(
      valueListenable: GlobalSession.instance.userNotifier,
      builder: (context, currentUser, _) {
        final userId = currentUser?.data?.id ?? '';
        final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';
        final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';
        final firstName = currentUser?.data?.firstName ?? '';
        final lastName = currentUser?.data?.lastName ?? '';
        final patientName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Patient';

        return BlocProvider<PatientOverViewBloc>(
          key: ValueKey(userId),
          create: (_) => sl<PatientOverViewBloc>()..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId)),
          child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
        builder: (context, state) {
          PatientOverViewEntity? overViewEntity;
          if (state is LoadPatientDataState) {
            overViewEntity = state.patientOverViewEntity;
          }

          final data = overViewEntity?.data;

          final List<PatientAppointmentEntity> allAppointments = List.from(data?.appointments ?? []);
          if (allAppointments.isEmpty) {
            final nextList = <NextAppointmentEntity>[];
            if (data?.upcomingAppointments != null && data!.upcomingAppointments!.isNotEmpty) {
              nextList.addAll(data.upcomingAppointments!);
            } else if (data?.nextAppointment != null) {
              nextList.add(data!.nextAppointment!);
            }
            for (final na in nextList) {
              allAppointments.add(
                PatientAppointmentEntity(
                  id: na.id?.toString() ?? na.appointmentId ?? '',
                  appointmentNumber: na.appointmentId ?? '',
                  appointmentDate: na.appointmentDate ?? na.formattedDate ?? '',
                  rawDate: na.appointmentDate,
                  startTime: na.startTime ?? na.formattedTime ?? '',
                  reason: na.reason ?? '',
                  status: na.status ?? 'Confirmed',
                  appointmentType: na.consultationType ?? 'In-Clinic',
                  isTeleConsultation: na.isTeleconsultation ?? false,
                  meetingUrl: na.meetingUrl ?? '',
                  hospitalName: na.hospitalName ?? '',
                  hospitalAddress: na.hospitalAddress ?? '',
                  hospitalPhone: na.hospitalPhone ?? '',
                  hospitalLogo: na.hospitalLogo ?? '',
                  doctorId: na.doctorId ?? '',
                  doctorName: na.doctorName ?? '',
                  patientName: patientName,
                ),
              );
            }
          }

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
                        child: _buildDashboardAvatar(_profileImagePath, patientName, primaryColor),
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
                FitnessSyncService.instance.syncNow(silent: true);
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

                    // Quick Services Section (Single Unified Master Card)
                    Container(
                      key: PatientTourController().quickServicesKey,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Services 6-Grid inside the single card
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 18, 8, 18),
                            child: GridView.count(
                              crossAxisCount: isTab ? 6 : 3,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 14,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: isTab ? 1.05 : 0.86,
                              children: [
                                // 1. Book Appointment
                                _buildServiceCard(
                                  context: context,
                                  title: 'Book\nAppointment',
                                  imagePath: 'assets/images/dashboard_icons/book_appointment_thick.png',
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

                                // 2. Prescriptions (Pill Icon)
                                _buildServiceCard(
                                  context: context,
                                  title: 'Prescriptions',
                                  imagePath: 'assets/images/dashboard_icons/pill_prescriptions_thick.png',
                                  isDark: isDark,
                                  isTab: isTab,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.userPrescriptionManagement,
                                  ),
                                ),

                                // 2. Health Records
                                _buildServiceCard(
                                  context: context,
                                  title: 'Health\nRecords',
                                  imagePath: 'assets/images/dashboard_icons/health_records_thick.png',
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
                                  imagePath: 'assets/images/dashboard_icons/my_vitals_thick.png',
                                  isDark: isDark,
                                  isTab: isTab,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.patientVitalsTracking,
                                  ),
                                ),

                                // 4. My Fitness (Quick Action)
                                _buildServiceCard(
                                  context: context,
                                  title: 'My Fitness',
                                  imagePath: 'assets/images/dashboard_icons/my_fitness_thick.png',
                                  isDark: isDark,
                                  isTab: isTab,
                                  onTap: () async {
                                    bool isConnected = FitnessSyncService.instance.isConnectedNotifier.value;
                                    if (!isConnected) {
                                      isConnected = await FitnessSyncService.instance.checkIsConnected();
                                    }
                                    if (!context.mounted) return;
                                    if (isConnected) {
                                      Navigator.pushNamed(context, AppRoutes.patientFitnessTracking);
                                    } else {
                                      Navigator.pushNamed(context, AppRoutes.patientConnectFitness);
                                    }
                                  },
                                ),

                                // 5. Doctor Suggestions
                                _buildServiceCard(
                                  context: context,
                                  title: 'Doctor\nSuggestions',
                                  imagePath: 'assets/images/dashboard_icons/doctor_suggestions_thick.png',
                                  isDark: isDark,
                                  isTab: isTab,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.patientDoctorSuggestions,
                                  ),
                                ),

                                // 6. My Family
                                _buildServiceCard(
                                  context: context,
                                  title: 'My Family',
                                  imagePath: 'assets/images/dashboard_icons/my_family_thick.png',
                                  isDark: isDark,
                                  isTab: isTab,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.patientMyFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                    const SizedBox(height: 20),

                    // 3. Upcoming Appointments Section
                    Container(
                      key: PatientTourController().upcomingAppointmentsKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.event_note_rounded,
                                      size: 17,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Appointments',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab ? 18 : 16,
                                      fontWeight: FontWeight.w700,
                                      color: adaptiveTextColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (upcomingAppointments.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${upcomingAppointments.length} Scheduled',
                                            style: const TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  if (widget.onNavigateTab != null) {
                                    widget.onNavigateTab!(1);
                                  } else {
                                    Navigator.pushNamed(context, AppRoutes.patientAppointments);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View All',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 11,
                                      color: primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (isLoading)
                            _buildAppointmentsShimmer(context, isDark)
                          else if (upcomingAppointments.isEmpty)
                            _buildNoAppointmentsCard(
                              context: context,
                              isDark: isDark,
                              isTab: isTab,
                              primaryColor: primaryColor,
                              userId: userId,
                              orgId: orgId,
                              hospitalId: hospitalId,
                            )
                          else
                            Column(
                              children: upcomingAppointments.map((apt) {
                                return _buildPatientAppointmentCard(
                                  context: context,
                                  apt: apt,
                                  patientName: patientName,
                                  userId: userId,
                                  orgId: orgId,
                                  hospitalId: hospitalId,
                                  isDark: isDark,
                                  isTab: isTab,
                                  primaryColor: primaryColor,
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
            ),
          );
        },
      );
    },
  ),
);
      },
    );
  }

  static String _formatTime12h(String rawTime) {
    final t = rawTime.trim();
    if (t.isEmpty) return 'Upcoming';
    if (t.contains('T') || t.contains('Z')) {
      final parsed = DateTime.tryParse(t);
      if (parsed != null) {
        final local = parsed.toLocal();
        var h = local.hour;
        final min = local.minute.toString().padLeft(2, '0');
        final ampm = h >= 12 ? 'PM' : 'AM';
        h = h % 12;
        if (h == 0) h = 12;
        return '$h:$min $ampm';
      }
    }
    if (t.toUpperCase().contains('AM') || t.toUpperCase().contains('PM')) {
      return t;
    }
    final parts = t.split(':');
    if (parts.isNotEmpty) {
      final h = int.tryParse(parts[0].trim());
      if (h != null) {
        final min = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0).toString().padLeft(2, '0') : '00';
        final ampm = h >= 12 ? 'PM' : 'AM';
        var hour12 = h % 12;
        if (hour12 == 0) hour12 = 12;
        return '$hour12:$min $ampm';
      }
    }
    return t;
  }

  static const _monthAbbr = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  Widget _buildPatientAppointmentCard({
    required BuildContext context,
    required PatientAppointmentEntity apt,
    required String patientName,
    required String userId,
    required String orgId,
    required String hospitalId,
    required bool isDark,
    required bool isTab,
    required Color primaryColor,
  }) {
    final docName = apt.doctorName.isNotEmpty ? apt.doctorName : 'Consulting Doctor';
    final hospitalName = apt.hospitalName.isNotEmpty ? apt.hospitalName : 'Yira Healthcare';
    final conditionOrSpecialty = apt.condition.isNotEmpty
        ? apt.condition
        : (apt.reason.isNotEmpty ? apt.reason : 'General Consultation');
    final isTele = apt.isTeleConsultation;

    // Parse date & time
    final parsedDt = _parseAppointmentDateTime(apt);
    final now = DateTime.now();
    final isToday = parsedDt != null &&
        parsedDt.year == now.year &&
        parsedDt.month == now.month &&
        parsedDt.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = parsedDt != null &&
        parsedDt.year == tomorrow.year &&
        parsedDt.month == tomorrow.month &&
        parsedDt.day == tomorrow.day;

    final String monthHeader;
    final String dayNumber;
    final String timeStr;

    if (parsedDt != null) {
      if (isToday) {
        monthHeader = 'TODAY';
      } else if (isTomorrow) {
        monthHeader = 'TMRW';
      } else {
        monthHeader = _monthAbbr[parsedDt.month - 1];
      }
      dayNumber = '${parsedDt.day}';

      // Format 12-hour time
      int hour = parsedDt.hour;
      final isPm = hour >= 12;
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      final minuteStr = parsedDt.minute.toString().padLeft(2, '0');
      final period = isPm ? 'PM' : 'AM';
      timeStr = '$hour:$minuteStr $period';
    } else {
      monthHeader = 'APPT';
      dayNumber = '--';
      timeStr = apt.startTime.isNotEmpty ? _formatTime12h(apt.startTime) : 'Upcoming';
    }

    final isDifferentPatient = apt.patientName.isNotEmpty &&
        apt.patientName.trim().toLowerCase() != 'patient' &&
        apt.patientName.trim().toLowerCase() != patientName.trim().toLowerCase();

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isToday
        ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.4 : 0.3)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: _PressableCard(
        onTap: () => _navigateToAppointmentDetails(
          context,
          apt,
          patientName,
          userId,
          orgId,
          hospitalId,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: isToday
                    ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.04)
                    : (isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.03)),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upper row: Date Badge + Doctor details + Mode badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Date Block (Practo style)
                  Container(
                    width: 64,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isToday
                          ? (isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                              : const Color(0xFFF0FDF4))
                          : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? const Color(0xFF10B981).withValues(alpha: 0.35)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Month Header Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          color: isToday
                              ? const Color(0xFF10B981)
                              : (isTomorrow
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          alignment: Alignment.center,
                          child: Text(
                            monthHeader,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isToday || isTomorrow
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Day Number
                        Expanded(
                          child: Center(
                            child: Text(
                              dayNumber,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                color: isToday
                                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                          ),
                        ),
                        // Time string
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Doctor details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Doctor name + Mode pill
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      docName,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab ? 15.5 : 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Compact Mode Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isTele
                                    ? (isDark
                                        ? const Color(0xFF312E81).withValues(alpha: 0.35)
                                        : const Color(0xFFEEF2FF))
                                    : (isDark
                                        ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                                        : const Color(0xFFECFDF5)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isTele
                                      ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                                      : const Color(0xFF10B981).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isTele ? Icons.videocam_rounded : Icons.local_hospital_rounded,
                                    size: 11,
                                    color: isTele ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    isTele ? 'Video' : 'In-Clinic',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isTele ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Condition or Specialty
                        Text(
                          conditionOrSpecialty,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 12.5 : 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Hospital / Clinic Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                hospitalName,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 11.5 : 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        if (isDifferentPatient) ...[
                          const SizedBox(height: 3),
                          Text(
                            'For: ${apt.patientName}',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
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

              const SizedBox(height: 10),

              // Bottom CTA Row (Single crisp full-width button)
              if (isTele)
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () {
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
                          const SnackBar(content: Text('No meeting link available yet.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.videocam_rounded, size: 15),
                    label: const Text(
                      'Join Video Consultation',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: Material(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _navigateToAppointmentDetails(
                        context,
                        apt,
                        patientName,
                        userId,
                        orgId,
                        hospitalId,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Appointment Details',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: BaseShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Date block shimmer
                    Container(
                      width: 64,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 7),
                          Container(
                            width: 90,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 110,
                            height: 10,
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
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNoAppointmentsCard({
    required BuildContext context,
    required bool isDark,
    required bool isTab,
    required Color primaryColor,
    required String userId,
    required String orgId,
    required String hospitalId,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTab ? 22 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A))
                .withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Layered icon with subtle radial glow
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      primaryColor.withValues(alpha: isDark ? 0.15 : 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.event_available_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Upcoming Appointments',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.w700,
                        fontSize: isTab ? 16 : 14.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Stay proactive about your health. Book an in-clinic visit or video call.',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12.5 : 11.5,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: primaryColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              icon: const Icon(Icons.calendar_today_rounded, size: 15),
              label: const Text(
                'Book Consultation',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required bool isDark,
    required bool isTab,
    required VoidCallback onTap,
  }) {
    return _PressableCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isTab ? 74 : 64,
            height: isTab ? 74 : 64,
            child: Image.asset(
              imagePath,
              width: isTab ? 74 : 64,
              height: isTab ? 74 : 64,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? 13 : 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
  static int _lastGlobalClickTime = 0;

  void _handleTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Debounce rapid taps/double-clicks across quick cards
    if (now - _lastGlobalClickTime < 750) {
      return;
    }
    _lastGlobalClickTime = now;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
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
