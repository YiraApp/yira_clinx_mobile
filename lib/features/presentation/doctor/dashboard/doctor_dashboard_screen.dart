
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/services/network_services/network_listener/network_listener.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/custom_chart.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/doc_appointment_card.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/doc_metric_card.dart';
import '../../../../core/app_navigation_drawer/app_navigation_drawer.dart';
import '../../../../core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';
import '../../../../core/shimmer_widgets/docor_dashboard_shimmer.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/appointments/appointment_entity.dart';
import 'doctor_dashboard_bloc/doctor_dashboard_bloc.dart';

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

  @override
  void dispose() {
    super.dispose();
  }

  double _calculateResponsiveChartHeight(BuildContext context) {
    final computedHeight = displayHeight(context) / 6;
    if (computedHeight < 110) return 110.0;
    if (computedHeight > 180) return 180.0;
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

    return NetworkListener(
      onOnline: () {
        _navigationDrawerBloc.add(const InitializeDrawerData());
        _dashboardBloc.add(FetchDoctorDashboardData());
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider<NavigationDrawerBloc>.value(
            value: _navigationDrawerBloc,
          ),
          BlocProvider<DoctorDashboardBloc>.value(value: _dashboardBloc),
        ],
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
              return current is! DoctorAppointmentsNav &&
                  current is! PatientManagementNav &&
                  current is! DocAndAppPatientDetailsNavState;
            },
            listener: (context, state) {
              if (state is DoctorAppointmentsNav) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.appointmentDashboardScreen,
                );
              } else if (state is PatientManagementNav) {
                Navigator.pushNamed(context, AppRoutes.patientManagementScreen);
              } else if (state is DocAndAppPatientDetailsNavState) {
                Navigator.pushNamed(context, AppRoutes.dashboardPatientDetails);
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        onPressed: () =>
                            _dashboardBloc.add(FetchDoctorDashboardData()),
                        child: const Text(
                          'Retry Operations',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is DoctorDashboardLoaded) {
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
                          _buildWelcomeCard(
                            context,
                            isDark,
                            primaryColor,
                            isTabletDevice,
                          ),
                          const SizedBox(height: fieldSpace),
                          _buildMetricsGrid(
                            context,
                            state,
                            primaryColor,
                            isTabletDevice,
                          ),
                          const SizedBox(height: fieldSpace),
                          _buildSectionHeader(
                            context,
                            "Today's Schedule",
                            "View Calendar",
                            isDark,
                            primaryColor,
                            () => context.read<DoctorDashboardBloc>().add(
                              ViewCalendarEvent(),
                            ),
                            isTabletDevice,
                          ),
                          const SizedBox(height: fieldSpace),
                        ]),
                      ),
                    ),

                    if (state.todaysAppointments.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(
                          context,
                          'No active appointments today',
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
                            final appointment = state.todaysAppointments[index];
                            final bool isVideo =
                                appointment.type == AppointmentType.videoCall;

                            return DocAppointmentCard(
                              initials: _getInitials(
                                appointment.patientName ?? 'Patient',
                              ),
                              name:
                                  appointment.patientName ?? 'Unknown Patient',
                              subtitle: isVideo
                                  ? 'Teleconsultation'
                                  : 'In-Clinic Visit',
                              description:
                                  appointment.reason ?? 'General Checkup',
                              timeOrDate:
                                  appointment.appointmentTime ?? '00:00 AM',
                              statusLabel: isVideo ? 'Live Video' : 'Confirmed',
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
                            );
                          }, childCount: state.todaysAppointments.length),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: screenHorizontalSpacePadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSectionHeader(
                            context,
                            "Recent Patients",
                            "View All",
                            isDark,
                            primaryColor,
                            () => context.read<DoctorDashboardBloc>().add(
                              ViewPatientsEvent(),
                            ),
                            isTabletDevice,
                          ),
                          const SizedBox(height: fieldSpace),
                        ]),
                      ),
                    ),

                    if (state.recentPatients.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(
                          context,
                          'No historical patient logs available',
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
                            final recentLog = state.recentPatients[index];
                            return DocAppointmentCard(
                              isTab: isTabletDevice,
                              initials: _getInitials(
                                recentLog.patientName ?? 'Patient',
                              ),
                              name: recentLog.patientName ?? 'Unknown Patient',
                              subtitle: 'Historical Consultation',
                              description:
                                  recentLog.diagnosis ??
                                  'Completed Session Case Log',
                              timeOrDate: recentLog.appointmentDate ?? 'Recent',
                              statusLabel: 'Completed',
                              statusColor: primaryColor.withOpacity(0.1),
                              statusTextColor: primaryColor,
                              onTap: () => context
                                  .read<DoctorDashboardBloc>()
                                  .add(DocAndAppPatientDetailsNavEvent()),
                            );
                          }, childCount: state.recentPatients.length),
                        ),
                      ),

                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: screenHorizontalSpacePadding,
                        right: screenHorizontalSpacePadding,
                        bottom: 50,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildChartCard(
                            context,
                            "Weekly Appointments",
                            "Avg: 5.4/day",
                            isDark,
                            _buildWeeklyChartBarList(
                              context,
                              primaryColor,
                              chartHeight,
                            ),
                            isTabletDevice,
                          ),
                          const SizedBox(height: fieldSpace),
                          _buildChartCard(
                            context,
                            "Monthly Patients",
                            "Yearly Total: 156",
                            isDark,
                            _buildMonthlyChartBarList(
                              context,
                              primaryColor,
                              chartHeight,
                            ),
                            isTabletDevice,
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    DoctorDashboardLoaded state,
    Color primaryColor,
    bool isTab,
  ) {
    final List<Widget> metricCards = [
      DocMetricCard(
        title: 'Today',
        value: '${state.todaysAppointments.length}',
        subtext: '0 completed',
        icon: Icons.calendar_today_outlined,
        iconColor: primaryColor,
        isTab: isTab,
      ),
      DocMetricCard(
        title: 'Patients',
        value: '4',
        subtext: '0 new this week',
        icon: Icons.person_outline_rounded,
        iconColor: primaryColor,
        isTab: isTab,
      ),
      DocMetricCard(
        title: 'Done',
        value: '0',
        subtext: '0 follow-ups',
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.teal,
        isTab: isTab,
      ),
      DocMetricCard(
        title: 'Stats',
        value: '0',
        subtext: '0 new patients',
        icon: Icons.analytics_outlined,
        iconColor: primaryColor,
        isTab: isTab,
      ),
    ];
    if (isTab) {
      return Row(
        children: List.generate(metricCards.length, (index) {
          final bool isLast = index == metricCards.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0.0 : fieldSpace),
              child: metricCards[index],
            ),
          );
        }),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: fieldSpace,
      crossAxisSpacing: fieldSpace,
      childAspectRatio: 1.5,
      children: metricCards,
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B).withOpacity(0.2)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16.0),
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

  Widget _buildWelcomeCard(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    final textWidth = displayWidth(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: isDark
            ? darkModeCardColor
            : const Color(0xFFd8eaff).withOpacity(0.4),
        border: Border.all(width: 0.5, color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? textWidth * 0.014 : textWidth * 0.028,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Dr. Rajesh Nagalingam',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? textWidth * 0.018 : textWidth * 0.044,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Dentist',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? textWidth * 0.015 : textWidth * 0.034,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          'Ocimum dental clinic, Journalist colony, Hyd 500034',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab
                                ? textWidth * 0.015
                                : textWidth * 0.03,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]!.withOpacity(0.4)
                    : primaryColor.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wb_sunny_outlined,
                color: Colors.amberAccent,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String actionText,
    bool isDark,
    Color primaryColor,
    VoidCallback onTap,
    bool isTab,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab
                ? displayWidth(context) * 0.02
                : displayWidth(context) * 0.038,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onTap,
          child: Text(
            actionText,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab
                  ? displayWidth(context) * 0.018
                  : displayWidth(context) * 0.032,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    String title,
    String badgeText,
    bool isDark,
    Widget chartContent,
    bool isTab,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(width: 0.5, color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab
                      ? displayWidth(context) * 0.02
                      : displayWidth(context) * 0.036,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab
                        ? displayWidth(context) * 0.014
                        : displayWidth(context) * 0.026,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          chartContent,
        ],
      ),
    );
  }

  Widget _buildWeeklyChartBarList(
    BuildContext context,
    Color primaryColor,
    double height,
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
    return CustomBarChart(
      values: const [6, 11, 1, 4, 9, 5, 2],
      labels: const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
      maxY: 12,
      barWidth: 14,
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
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Color> beautifulMonthlyColors = List.generate(12, (index) {
      final double progress = index / 11;
      final Color endAccent = isDark
          ? const Color(0xFF2DD4BF)
          : const Color(0xFF0F766E);
      return Color.lerp(primaryColor, endAccent, progress)!;
    });
    return CustomBarChart(
      isTab: isTablet(context),
      monthly: true,
      values: const [35, 48, 55, 68, 15, 22, 44, 62, 52, 30, 38, 18],
      labels: const [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ],
      maxY: 75,
      barWidth: 8,
      chartHeight: height,
      barColors: beautifulMonthlyColors,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      tooltipSuffix: 'Patients',
      fontFamily: appPoppinFont,
    );
  }
}
