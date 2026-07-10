import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/services/network_services/network_listener/network_listener.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/custom_chart.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/dashboard_metric_grid.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/doc_appointment_card.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/welocme_card.dart';
import '../../../../core/app_navigation_drawer/app_navigation_drawer.dart';
import '../../../../core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';
import '../../../../core/shimmer_widgets/docor_dashboard_shimmer.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/dashboard/doctor_dashboard_entity.dart';
import 'doctor_dashboard_bloc/doctor_dashboard_bloc.dart';

import 'widgets/dashboard_section_header.dart';
import 'widgets/dashboard_chart_card.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  late final DoctorDashboardBloc _dashboardBloc;
  late final NavigationDrawerBloc _navigationDrawerBloc;

  @override
  void initState() {
    super.initState();
    _navigationDrawerBloc = sl<NavigationDrawerBloc>()
      ..add(const InitializeDrawerData());
    _dashboardBloc = sl<DoctorDashboardBloc>()..add(FetchDoctorDashboardData());
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
    if (name.isEmpty) return 'P';
    final parts = name.trim().split(' ');
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
          drawer: const AppNavigationDrawer(),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: scaffoldBg,
            iconTheme: IconThemeData(color: adaptiveTextColor),
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              projectTitle,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTabletDevice ? width * 0.022 : width * 0.046,
                fontWeight: FontWeight.w700,
                color: adaptiveTextColor,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_outlined,
                  color: adaptiveTextColor,
                ),
                onPressed: () {},
              ),
              const Padding(
                padding: EdgeInsets.only(right: screenHorizontalSpacePadding),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
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
                await Navigator.pushNamed(context, AppRoutes.patientManagementScreen);
                if (context.mounted) {
                  _dashboardBloc.add(ClearNavigationTriggerEvent());
                }
              } else if (state is DocAndAppPatientDetailsNavState) {
                await Navigator.pushNamed(context, AppRoutes.dashboardPatientDetails);
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
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          color: Colors.red,
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
                                (isTablet(context) ? 0.026 : 0.035),
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
              } else if (state is DocAndAppPatientDetailsNavState) {
                workingEntity = state.dashboardEntity;
              } else if (state is DoctorAppointmentsNav) {
                workingEntity = state.dashboardEntity;
              } else if (state is PatientManagementNav) {
                workingEntity = state.dashboardEntity;
              }

              if (workingEntity != null) {
                final dashboard = workingEntity.data;

                if (dashboard == null) {
                  return Center(
                    child: _buildEmptyState(
                      context,
                      'Dashboard parameters uninitialized.',
                    ),
                  );
                }

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: screenHorizontalSpacePadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 8.0),

                          WelcomeCard(
                            name: dashboard.profile.name.isNotEmpty
                                ? dashboard.profile.name
                                : "Doctor",
                            specialty: dashboard.profile.specialty.isNotEmpty
                                ? dashboard.profile.specialty
                                : "Medical Professional",
                            clinicAddress:
                            dashboard.profile.clinicAddress.isNotEmpty
                                ? dashboard.profile.clinicAddress
                                : "Clinic Location N/A",
                            primaryColor: primaryColor,
                            isDark: isDark,
                            isTab: isTabletDevice,
                            fontFamily: appPoppinFont,
                          ),
                          const SizedBox(height: fieldSpace),

                          DashboardMetricsGrid(
                            metrics: dashboard.metrics,
                            primaryColor: primaryColor,
                            isTab: isTabletDevice,
                          ),
                          const SizedBox(height: fieldSpace),

                          DashboardSectionHeader(
                            title: "Today's Schedule",
                            actionText: "View Calendar",
                            isDark: isDark,
                            primaryColor: primaryColor,
                            onTap: () => context
                                .read<DoctorDashboardBloc>()
                                .add(ViewCalendarEvent()),
                            isTab: isTabletDevice,
                            fontFamily: appPoppinFont,
                          ),
                          const SizedBox(height: 8.0),
                        ]),
                      ),
                    ),

                    if (dashboard.todaysSchedule.isEmpty)
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
                            final appointment = dashboard.todaysSchedule[index];
                            final bool isVideo =
                                appointment.statusTag.toUpperCase() ==
                                    'LIVE VIDEO';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: DocAppointmentCard(
                                initials: _getInitials(appointment.patientName),
                                name: appointment.patientName.isNotEmpty
                                    ? appointment.patientName
                                    : 'Unknown Patient',
                                subtitle:
                                appointment.consultationType.isNotEmpty
                                    ? appointment.consultationType
                                    : 'Consultation',
                                description: appointment.reason.isNotEmpty
                                    ? appointment.reason
                                    : 'General Checkup',
                                timeOrDate: appointment.time.isNotEmpty
                                    ? appointment.time
                                    : '--:-- AM',
                                statusLabel: appointment.statusTag.isNotEmpty
                                    ? appointment.statusTag
                                    : 'Confirmed',
                                statusColor: isVideo
                                    ? Colors.amber.withOpacity(0.15)
                                    : Colors.green.withOpacity(0.15),
                                statusTextColor: isVideo
                                    ? Colors.amber[800]!
                                    : Colors.green[700]!,
                                onTap: () => context
                                    .read<DoctorDashboardBloc>()
                                    .add(DocAndAppPatientDetailsNavEvent()),
                                isTab: isTabletDevice,
                              ),
                            );
                          }, childCount: dashboard.todaysSchedule.length),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: screenHorizontalSpacePadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          DashboardSectionHeader(
                            title: "Recent Patients",
                            actionText: "View All",
                            isDark: isDark,
                            primaryColor: primaryColor,
                            onTap: () => context
                                .read<DoctorDashboardBloc>()
                                .add(ViewPatientsEvent()),
                            isTab: isTabletDevice,
                            fontFamily: appPoppinFont,
                          ),
                          const SizedBox(height: 8.0),
                        ]),
                      ),
                    ),

                    if (dashboard.recentPatients.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: screenHorizontalSpacePadding,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildEmptyState(
                            context,
                            'No historical patient logs available',
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
                            final recentLog = dashboard.recentPatients[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: DocAppointmentCard(
                                isTab: isTabletDevice,
                                initials: _getInitials(recentLog.name),
                                name: recentLog.name.isNotEmpty
                                    ? recentLog.name
                                    : 'Unknown Patient',
                                subtitle: recentLog.consultationType.isNotEmpty
                                    ? recentLog.consultationType
                                    : 'Historical Log',
                                description: recentLog.condition.isNotEmpty
                                    ? recentLog.condition
                                    : 'Case history logs completed',
                                timeOrDate: recentLog.date.isNotEmpty
                                    ? recentLog.date
                                    : 'Recent',
                                statusLabel: recentLog.status.isNotEmpty
                                    ? recentLog.status
                                    : 'Completed',
                                statusColor: primaryColor.withOpacity(0.1),
                                statusTextColor: primaryColor,
                                onTap: () => context
                                    .read<DoctorDashboardBloc>()
                                    .add(DocAndAppPatientDetailsNavEvent()),
                              ),
                            );
                          }, childCount: dashboard.recentPatients.length),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: screenHorizontalSpacePadding,
                        right: screenHorizontalSpacePadding,
                        bottom: 40.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          DashboardChartCard(
                            title: "Weekly Appointments",
                            badgeText:
                            "Avg: ${dashboard.weeklyAppointments.averagePerDay}/day",
                            isDark: isDark,
                            isTab: isTabletDevice,
                            fontFamily: appPoppinFont,
                            chartContent:
                            dashboard.weeklyAppointments.dailyData.isEmpty
                                ? _buildInlineChartEmptyState(
                              context,
                              'No tracking data logged this week.',
                            )
                                : _buildWeeklyChartBarList(
                              context,
                              primaryColor,
                              chartHeight,
                              dashboard.weeklyAppointments.xLabels,
                              dashboard.weeklyAppointments.yValues,
                            ),
                          ),
                          const SizedBox(height: fieldSpace),

                          DashboardChartCard(
                            title: "Monthly Patients",
                            badgeText:
                            "Yearly Total: ${dashboard.monthlyPatients.yearlyTotal}",
                            isDark: isDark,
                            isTab: isTabletDevice,
                            fontFamily: appPoppinFont,
                            chartContent:
                            dashboard.monthlyPatients.monthlyData.isEmpty
                                ? _buildInlineChartEmptyState(
                              context,
                              'No tracking data logged this year.',
                            )
                                : _buildMonthlyChartBarList(
                              context,
                              primaryColor,
                              chartHeight,
                              dashboard.monthlyPatients.xLabels,
                              dashboard.monthlyPatients.yValues,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
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
      List<String> labels,
      List<double> values,
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
    final double highestValue = values.isEmpty
        ? 10.0
        : values.reduce((a, b) => a > b ? a : b);
    final double computedMaxY = highestValue == 0 ? 12.0 : highestValue * 1.25;

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
      List<String> labels,
      List<double> values,
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
    final double highestValue = values.isEmpty
        ? 50.0
        : values.reduce((a, b) => a > b ? a : b);
    final double computedMaxY = highestValue == 0 ? 40.0 : highestValue * 1.30;

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