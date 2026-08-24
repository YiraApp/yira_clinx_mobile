import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/services/network_services/network_listener/network_listener.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/custom_chart.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_metric_grid.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/doc_appointment_card.dart';
import '../../../../core/app_bottom_nav_bar/app_bottom_nav_bar.dart';
import '../../../../core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';
import '../../../../core/shimmer_widgets/docor_dashboard_shimmer.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/utils.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/dashboard/doctor_dashboard_entity.dart';
import 'dashboard_patient_details_screen.dart';
import 'doctor_dashboard_bloc/doctor_dashboard_bloc.dart';

import 'package:yiraclinics/core/services/notification_services/notification_services.dart';
import 'package:yiraclinics/features/use_cases/notifications/get_notifications_use_case.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/features/data/repository_impl/notifications/notifications_repo_impl.dart';

import 'widgets/dashboard_section_header.dart';
import 'widgets/dashboard_chart_card.dart';
import '../profile/widgets/profile_switcher_sheet.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final bool isShellChild;
  const DoctorDashboardScreen({super.key, this.isShellChild = false});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  late final DoctorDashboardBloc _dashboardBloc;
  late final NavigationDrawerBloc _navigationDrawerBloc;
  final ValueNotifier<int> _unreadNotificationsCount = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _navigationDrawerBloc = sl<NavigationDrawerBloc>()
      ..add(const InitializeDrawerData());
    _dashboardBloc = sl<DoctorDashboardBloc>()..add(FetchDoctorDashboardData());
    _fetchUnreadNotificationsCount();
    NotificationService.instance.syncFcmTokenWithBackend();
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    try {
      GetNotificationsUseCase useCase;
      if (sl.isRegistered<GetNotificationsUseCase>()) {
        useCase = sl<GetNotificationsUseCase>();
      } else {
        useCase = GetNotificationsUseCase(
          repository: NotificationsRepositoryImpl(apiClient: sl<ApiClient>()),
        );
      }
      final result = await useCase.call(page: 1, limit: 1);
      if (result != null && mounted) {
        _unreadNotificationsCount.value = result.unreadCount;
      }
    } catch (e) {
      debugPrint("Error fetching unread notifications count: $e");
    }
  }

  @override
  void dispose() {
    _unreadNotificationsCount.dispose();
    super.dispose();
  }

  double _calculateResponsiveChartHeight(BuildContext context) {
    final bool isTabletDevice = isTablet(context);
    final double divisor = isTabletDevice ? 4.2 : 4.8;
    final double computedHeight = displayHeight(context) / divisor;

    if (isTabletDevice) {
      if (computedHeight < 200.0) return 200.0;
      if (computedHeight > 340.0) return 340.0;
    } else {
      if (computedHeight < 140.0) return 140.0;
      if (computedHeight > 200.0) return 200.0;
    }
    return computedHeight;
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'P';
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = Theme.of(context).primaryColor;
    final chartHeight = _calculateResponsiveChartHeight(context);
    final width = displayWidth(context);
    final isTabletDevice = isTablet(context);
    final adaptiveTextColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationDrawerBloc>.value(value: _navigationDrawerBloc),
        BlocProvider<DoctorDashboardBloc>(create: (context) => _dashboardBloc),
      ],
      child: NetworkListener(
        onOnline: () {
          if (_dashboardBloc.state is! DoctorDashboardSuccessState &&
              _dashboardBloc.state is! DoctorDashboardLoading) {
            _navigationDrawerBloc.add(const InitializeDrawerData());
            _dashboardBloc.add(FetchDoctorDashboardData());
          }
        },
        child: Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: widget.isShellChild ? null : const AppBottomNavBar(currentIndex: 0),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: scaffoldBg,
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
                    width: isTabletDevice ? 32 : 28,
                    height: isTabletDevice ? 32 : 28,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: BlocBuilder<DoctorDashboardBloc, DoctorDashboardState>(
                    bloc: _dashboardBloc,
                    builder: (context, state) {
                      if (state is! DoctorDashboardSuccessState) {
                        return BaseShimmer(
                          child: Container(
                            width: isTabletDevice ? 160 : 130,
                            height: isTabletDevice ? 20 : 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                      }

                      final hName = state.dashboardEntity.data?.hospitalName;
                      final hospitalTitle = (hName != null && hName.trim().isNotEmpty)
                          ? hName.trim()
                          : 'Healthcare Facility';

                      return GestureDetector(
                        onTap: () => ProfileSwitcherSheet.show(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                hospitalTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTabletDevice ? width * 0.022 : 18.0,
                                  fontWeight: FontWeight.w700,
                                  color: adaptiveTextColor,
                                  letterSpacing: -0.5,
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
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder<int>(
                valueListenable: _unreadNotificationsCount,
                builder: (context, count, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: "Notifications",
                        icon: Icon(
                          Icons.notifications_none_outlined,
                          color: adaptiveTextColor,
                          size: isTabletDevice ? 24 : 22,
                        ),
                        onPressed: () async {
                          await Navigator.pushNamed(context, AppRoutes.recentNotifications);
                          _fetchUnreadNotificationsCount();
                        },
                      ),
                      if (count > 0)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: scaffoldBg,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  count > 99 ? "99+" : "$count",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: screenHorizontalSpacePadding),
                child: BlocBuilder<DoctorDashboardBloc, DoctorDashboardState>(
                  bloc: _dashboardBloc,
                  builder: (context, state) {
                    String? photoUrl;
                    if (state is DoctorDashboardSuccessState) {
                      photoUrl = state.dashboardEntity.data?.profile?.profileImageUrl ??
                          state.dashboardEntity.data?.profile?.imagePath;
                    }
                    final double size = isTabletDevice ? 38 : 34;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.profile);
                      },
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (photoUrl != null && photoUrl.trim().isNotEmpty)
                            ? Image.network(
                                photoUrl.trim(),
                                width: size,
                                height: size,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Icon(
                                  Icons.person_rounded,
                                  color: primaryColor,
                                  size: isTabletDevice ? 20 : 18,
                                ),
                              )
                            : Icon(
                                Icons.person_rounded,
                                color: primaryColor,
                                size: isTabletDevice ? 20 : 18,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          body: BlocConsumer<DoctorDashboardBloc, DoctorDashboardState>(
            bloc: _dashboardBloc,
            buildWhen: (previous, current) {
              return current is DoctorDashboardSuccessState ||
                  current is DoctorDashboardLoading ||
                  current is DoctorDashboardError ||
                  current is DoctorAppointmentsNav ||
                  current is PatientManagementNav ||
                  current is DocAndAppPatientDetailsNavState;
            },
            listener: (context, state) async {
              if (state is DoctorAppointmentsNav) {
                await Navigator.pushNamed(
                  context,
                  AppRoutes.appointmentDashboardScreen,
                );
                if (context.mounted) {
                  _dashboardBloc.add(ClearNavigationTriggerEvent());
                }
              } else if (state is PatientManagementNav) {
                await Navigator.pushNamed(
                  context,
                  AppRoutes.patientManagementScreen,
                );
                if (context.mounted) {
                  _dashboardBloc.add(ClearNavigationTriggerEvent());
                }
              } else if (state is DocAndAppPatientDetailsNavState) {
                final isRecent = state.patientDetails.isRecent == true;
                final pid = isRecent
                    ? state.patientDetails.recentPatients?.patientUserId
                    : state.patientDetails.todaysSchedule?.patientUserId;
                final aid = isRecent
                    ? state.patientDetails.recentPatients?.appointmentId
                    : state.patientDetails.todaysSchedule?.appointmentId;
                final hid = isRecent
                    ? state.patientDetails.recentPatients?.hospitalId
                    : state.patientDetails.todaysSchedule?.hospitalId;
                final oid = isRecent
                    ? state.patientDetails.recentPatients?.orgId
                    : state.patientDetails.todaysSchedule?.orgId;
                final name = isRecent
                    ? state.patientDetails.recentPatients?.name
                    : state.patientDetails.todaysSchedule?.patientName;

                await Navigator.pushNamed(
                  context,
                  AppRoutes.doctorPatientProfileScreen,
                  arguments: {
                    'patientId': pid?.toString(),
                    'appointmentId': aid?.toString(),
                    'hospitalId': hid?.toString(),
                    'orgId': oid?.toString(),
                    'patientName': name,
                    'initialTabIndex': 0,
                  },
                );
                if (context.mounted) {
                  _dashboardBloc.add(ClearNavigationTriggerEvent());
                }
              }
            },
            builder: (context, state) {
              if (state is DoctorDashboardLoading) {
                return DoctorDashboardShimmer(fontFamily: appPoppinFont);
              }
              if (state is DoctorDashboardError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          color: Colors.red,
                          fontSize:
                              displayWidth(context) *
                              (isTabletDevice ? 0.018 : 0.03),
                        ),
                      ),
                      const SizedBox(height: fieldSpace),
                      TextButton(
                        onPressed: () =>
                            _dashboardBloc.add(FetchDoctorDashboardData()),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Retry Operations',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize:
                                displayWidth(context) *
                                (isTablet(context) ? 0.026 : 0.032),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              DoctorDashboardEntity? workingEntity;
              if (state is DoctorDashboardSuccessState) {
                workingEntity = state.dashboardEntity;
              } else if (state is DoctorAppointmentsNav) {
                workingEntity = state.dashboardEntity;
              } else if (state is PatientManagementNav) {
                workingEntity = state.dashboardEntity;
              }

              if (workingEntity != null) {
                final dashboard = workingEntity.data;

                if (dashboard == null) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      _fetchUnreadNotificationsCount();
                      NotificationService.instance.syncFcmTokenWithBackend();
                      _dashboardBloc.add(const FetchDoctorDashboardData(isRefresh: true));
                      await _dashboardBloc.stream.firstWhere(
                        (state) => state is DoctorDashboardSuccessState || state is DoctorDashboardError,
                      ).timeout(const Duration(seconds: 10), onTimeout: () => state);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: displayHeight(context) * 0.7,
                        alignment: Alignment.center,
                        child: _buildEmptyState(
                          context,
                          'Dashboard parameters uninitialized.',
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _fetchUnreadNotificationsCount();
                    NotificationService.instance.syncFcmTokenWithBackend();
                    _dashboardBloc.add(const FetchDoctorDashboardData(isRefresh: true));
                    await _dashboardBloc.stream.firstWhere(
                      (state) => state is DoctorDashboardSuccessState || state is DoctorDashboardError,
                    ).timeout(const Duration(seconds: 10), onTimeout: () => state);
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: screenHorizontalSpacePadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 12.0),

                          DashboardMetricsGrid(
                            metrics: dashboard.metrics!,
                            primaryColor: primaryColor,
                            isTab: isTabletDevice,
                          ),
                          const SizedBox(height: 20.0),

                          DashboardSectionHeader(
                            title: "Today's Schedule",
                            countBadge: "${dashboard.todaysSchedule?.length ?? 0}",
                            actionText: "View Appointments",
                            isDark: isDark,
                            primaryColor: primaryColor,
                            onTap: () => context
                                .read<DoctorDashboardBloc>()
                                .add(ViewCalendarEvent()),
                            isTab: isTabletDevice,
                            fontFamily: appPoppinFont,
                          ),
                          const SizedBox(height: 10.0),
                        ]),
                      ),
                    ),

                    if (dashboard.todaysSchedule?.isEmpty ?? true)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: screenHorizontalSpacePadding,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildEmptyState(
                            context,
                            'No active appointments today',
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: screenHorizontalSpacePadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final appointment =
                                dashboard.todaysSchedule?[index];
                            final bool isVideo =
                                appointment?.statusTag?.toUpperCase() ==
                                'LIVE VIDEO';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: DocAppointmentCard(
                                initials: _getInitials(
                                  appointment?.patientName ?? '',
                                ),
                                name:
                                    appointment?.patientName?.isNotEmpty ??
                                        false
                                    ? appointment?.patientName ?? ''
                                    : 'Unknown Patient',
                                subtitle:
                                    appointment?.consultationType?.isNotEmpty ??
                                        false
                                    ? appointment?.consultationType ?? ''
                                    : 'Consultation',
                                description:
                                    appointment?.reason?.isNotEmpty ?? false
                                    ? appointment?.reason ?? ''
                                    : 'General Checkup',
                                timeOrDate:
                                    appointment?.time?.isNotEmpty ?? false
                                    ? appointment?.time ?? ''
                                    : '--:-- AM',
                                statusLabel:
                                    appointment?.statusTag?.isNotEmpty ??
                                        false
                                    ? appointment?.statusTag ?? ''
                                    : 'Confirmed',
                                statusColor: isVideo
                                    ? Colors.amber.withValues(alpha: 0.15)
                                    : Colors.green.withValues(alpha: 0.15),
                                statusTextColor: isVideo
                                    ? Colors.amber[800]!
                                    : Colors.green[700]!,
                                patientStatus: appointment?.patientStatus ?? 'Active',
                                onTap: () {
                                  var data = DashboardPatientDetails(
                                    appointment,
                                    null,
                                    false
                                  );
                                  context.read<DoctorDashboardBloc>().add(
                                    DocAndAppPatientDetailsNavEvent(data),
                                  );
                                },
                                isTab: isTabletDevice,
                                isTeleConsultation: isVideo,
                                onJoinCall: () async {
                                  final meetingUrl = appointment?.meetingUrl;
                                  if (meetingUrl != null && meetingUrl.isNotEmpty) {
                                    await Utils.launchURL(
                                      meetingUrl,
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
                                      const SnackBar(content: Text('No Zoom meeting link found for this appointment.')),
                                    );
                                  }
                                },
                              ),
                            );
                          }, childCount: dashboard.todaysSchedule?.length),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: screenHorizontalSpacePadding,
                        right: screenHorizontalSpacePadding,
                        top: 14.0,
                        bottom: 40.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          DashboardChartCard(
                            title: "Weekly Appointments",
                            badgeText:
                                "Avg: ${dashboard.weeklyAppointments?.averagePerDay}/day",
                            isDark: isDark,
                            isTab: isTabletDevice,
                            fontFamily: appPoppinFont,
                            chartContent:
                                dashboard
                                        .weeklyAppointments
                                        ?.dailyData
                                        ?.isEmpty ??
                                    false
                                ? _buildInlineChartEmptyState(
                                    context,
                                    'No tracking data logged this week.',
                                  )
                                : _buildWeeklyChartBarList(
                                    context,
                                    primaryColor,
                                    chartHeight,
                                    dashboard.weeklyAppointments?.xLabels ?? [],
                                    dashboard.weeklyAppointments?.yValues ?? [],
                                  ),
                          ),
                          const SizedBox(height: fieldSpace),

                          DashboardChartCard(
                            title: "Monthly Patients",
                            badgeText:
                                "Yearly Total: ${dashboard.monthlyPatients?.yearlyTotal}",
                            isDark: isDark,
                            isTab: isTabletDevice,
                            fontFamily: appPoppinFont,
                            chartContent:
                                dashboard
                                        .monthlyPatients
                                        ?.monthlyData
                                        ?.isEmpty ??
                                    false
                                ? _buildInlineChartEmptyState(
                                    context,
                                    'No tracking data logged this year.',
                                  )
                                : _buildMonthlyChartBarList(
                                    context,
                                    primaryColor,
                                    chartHeight,
                                    dashboard.monthlyPatients?.xLabels ?? [],
                                    dashboard.monthlyPatients?.yValues ?? [],
                                  ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            }

              return const Center(child: CircularProgressIndicator.adaptive());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B).withOpacity(0.2)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: displayWidth(context) * 0.034,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineChartEmptyState(BuildContext context, String explanation) {
    return Container(
      width: double.infinity,
      height: _calculateResponsiveChartHeight(context),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 36,
            color: Colors.grey.withOpacity(0.4),
          ),
          const SizedBox(height: 6.0),
          Text(
            explanation,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.03,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChartBarList(
    BuildContext context,
    Color primaryColor,
    double height,
    List<String?> labels,
    List<double?> values,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Color> beautifulWeeklyPalette = [
      primaryColor,
      isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
      isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
      isDark ? const Color(0xFF6EE7B7) : const Color(0xFF34D399),
      isDark ? const Color(0xFF059669) : const Color(0xFF14532D),
      isDark ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
      isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
    ];
    double highestValue = 0.0;
    for (final v in values) {
      if (v != null && v > highestValue) {
        highestValue = v;
      }
    }
    final double computedMaxY = highestValue <= 0 ? 12.0 : highestValue * 1.25;

    return CustomBarChart(
      values: values,
      labels: labels,
      maxY: computedMaxY,
      chartHeight: height,
      barColors: beautifulWeeklyPalette,
      fontFamily: appPoppinFont,
      tooltipSuffix: 'Appointments',
      isTab: isTablet(context),
    );
  }

  Widget _buildMonthlyChartBarList(
    BuildContext context,
    Color primaryColor,
    double height,
    List<String?> labels,
    List<double?> values,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Color> beautifulMonthlyColors = List.generate(12, (index) {
      final double progress = index / 11;
      return Color.lerp(
        primaryColor,
        isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
        progress,
      )!;
    });
    double highestValue = 0.0;
    for (final v in values) {
      if (v != null && v > highestValue) {
        highestValue = v;
      }
    }
    final double computedMaxY = highestValue <= 0 ? 40.0 : highestValue * 1.30;

    return CustomBarChart(
      isTab: isTablet(context),
      monthly: true,
      values: values,
      labels: labels,
      maxY: computedMaxY,
      chartHeight: height,
      barColors: beautifulMonthlyColors,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      tooltipSuffix: 'Patients',
      fontFamily: appPoppinFont,
    );
  }
}
