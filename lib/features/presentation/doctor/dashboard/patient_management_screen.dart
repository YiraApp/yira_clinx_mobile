import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/app_bottom_nav_bar/app_bottom_nav_bar.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_dashboard_bloc/dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/patient_card.dart';
import '../../../../core/common_drop_down/common_drop_down.dart';
import '../../../../core/constants/constants.dart';

class PatientManagementScreen extends StatelessWidget {
  final bool isShellChild;
  const PatientManagementScreen({super.key, this.isShellChild = false});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return BlocProvider(
      create: (context) => DashboardBloc()..add(const GetDashboardData()),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          bottomNavigationBar: isShellChild ? null : const AppBottomNavBar(currentIndex: 2),
          body: SafeArea(
            child: BlocConsumer<DashboardBloc, DashboardState>(
              buildWhen: (previous, state) => state is! ViewPatientDetailsState,
              listener: (context, state) {
                if (state is ViewPatientDetailsState) {
                  final currentUser = GlobalSession.instance.userNotifier.value;
                  final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '';
                  final orgId = currentUser?.data?.latestOrgId?.toString() ?? '';
                  Navigator.pushNamed(
                    context,
                    AppRoutes.doctorPatientProfileScreen,
                    arguments: {
                      'patientId': state.patientId,
                      'patientName': state.patientName,
                      'hospitalId': hospitalId,
                      'orgId': orgId,
                      'initialTabIndex': 0,
                    },
                  );
                }
              },
              builder: (context, state) {
                if (state.status == DashboardStatus.loading) {
                  return const ListCardShimmer(itemCount: 5);
                }

                final totalPatients = state.allPatients.length.toString();
                final activeCases = state.allPatients.where((p) => p.status.toLowerCase() == 'active').length.toString();
                final totalVisits = state.allPatients.fold(0, (sum, p) => sum + p.visits).toString();

                return NestedScrollView(
                  physics: const BouncingScrollPhysics(),
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // 1. Title Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: screenHorizontalSpacePadding,
                            right: screenHorizontalSpacePadding,
                            top: screenTopPadding,
                            bottom: fieldSpace,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Patient Management",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab
                                      ? displayWidth(context) * 0.022
                                      : displayWidth(context) * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Unified view of patients, medical records, and clinical notes",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab
                                      ? displayWidth(context) * 0.018
                                      : displayWidth(context) * 0.03,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Sticky persistently pinned header
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickySearchHeaderDelegate(
                          child: Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: screenHorizontalSpacePadding,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                _buildHeader(context, isDark, isTab),
                              ],
                            ),
                          ),
                          headerHeight: isTab ? 140.0 : 130.0,
                        ),
                      ),
                    ];
                  },
                  body: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: screenHorizontalSpacePadding,
                    ),
                    child:
                        state.status == DashboardStatus.success &&
                            state.patients.isEmpty
                        ? const Center(
                            child: Text(
                              "No patients found",
                              style: TextStyle(fontFamily: appPoppinFont),
                            ),
                          )
                        : CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              // Spacing below the pinned search filters header
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 16),
                              ),

                              // Metrics Component Section integrated cleanly as a sliver layout element
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 110,
                                  child: isTab
                                      ? Row(
                                          children: [
                                            Expanded(
                                              child: _buildMetricCard(
                                                context: context,
                                                title: "Total Patients",
                                                value: totalPatients,
                                                icon: Icons
                                                    .person_outline_rounded,
                                                iconColor: Colors
                                                    .deepPurpleAccent
                                                    .withOpacity(0.6),
                                                valueColor: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                                isTab: isTab,
                                              ),
                                            ),
                                            const SizedBox(width: fieldSpace),
                                            Expanded(
                                              child: _buildMetricCard(
                                                isTab: isTab,
                                                context: context,
                                                title: "Active Cases",
                                                value: activeCases,
                                                icon: Icons.timeline_rounded,
                                                iconColor: Colors.green
                                                    .withOpacity(0.6),
                                                valueColor:
                                                    Colors.green.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: fieldSpace),
                                            /*Expanded(
                                              child: _buildMetricCard(
                                                isTab: isTab,
                                                context: context,
                                                title: "Critical Cases",
                                                value: "0",
                                                icon: Icons
                                                    .favorite_border_rounded,
                                                iconColor: Colors.redAccent
                                                    .withOpacity(0.6),
                                                valueColor: Colors.red.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: fieldSpace),*/
                                            Expanded(
                                              child: _buildMetricCard(
                                                isTab: isTab,
                                                context: context,
                                                title: "Total Visits",
                                                value: totalVisits,
                                                icon:
                                                    Icons.description_outlined,
                                                iconColor: Colors.indigoAccent
                                                    .withOpacity(0.6),
                                                valueColor:
                                                    Colors.indigo.shade700,
                                              ),
                                            ),
                                          ],
                                        )
                                      : ListView(
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          children: [
                                            SizedBox(
                                              width: 140,
                                              child: _buildMetricCard(
                                                context: context,
                                                title: "Total Patients",
                                                value: totalPatients,
                                                icon: Icons
                                                    .person_outline_rounded,
                                                iconColor: Colors
                                                    .deepPurpleAccent
                                                    .withOpacity(0.6),
                                                valueColor: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                                isTab: isTab,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            SizedBox(
                                              width: 140,
                                              child: _buildMetricCard(
                                                isTab: isTab,
                                                context: context,
                                                title: "Active Cases",
                                                value: activeCases,
                                                icon: Icons.timeline_rounded,
                                                iconColor: Colors.green
                                                    .withOpacity(0.6),
                                                valueColor:
                                                    Colors.green.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            /*SizedBox(
                                              width: 140,
                                              child: _buildMetricCard(
                                                isTab: isTab,
                                                context: context,
                                                title: "Critical Cases",
                                                value: "0",
                                                icon: Icons
                                                    .favorite_border_rounded,
                                                iconColor: Colors.redAccent
                                                    .withOpacity(0.6),
                                                valueColor: Colors.red.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 12),*/
                                            SizedBox(
                                              width: 140,
                                              child: _buildMetricCard(
                                                isTab: isTab,
                                                context: context,
                                                title: "Total Visits",
                                                value: totalVisits,
                                                icon:
                                                    Icons.description_outlined,
                                                iconColor: Colors.indigoAccent
                                                    .withOpacity(0.6),
                                                valueColor:
                                                    Colors.indigo.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              // Spacing layout helper between metric row and list elements
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 16),
                              ),

                              // The Main Patient List View rendering safely
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    key: ValueKey(
                                      state.patients[index].id,
                                    ),
                                    child: PatientCard(
                                      isTab: isTab,
                                      patient: state.patients[index],
                                      onTap: () {
                                        context.read<DashboardBloc>().add(
                                          ViewPatientDetailsEvent(
                                            patientId:
                                                state.patients[index].userId,
                                            patientName:
                                                state.patients[index].name,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }, childCount: state.patients.length),
                              ),

                              // Bottom spacer layout helper for list ending overscroll feel
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 24),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color valueColor,
    required bool isTab,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTab ? 12 : 14,
        vertical: isTab ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  darkModeCardColor,
                  darkModeCardColor.withOpacity(0.8),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  iconColor.withOpacity(0.03),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? iconColor.withOpacity(0.15)
              : iconColor.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: iconColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withOpacity(isDark ? 0.2 : 0.12),
                  iconColor.withOpacity(isDark ? 0.08 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: isTab ? 18 : 16, color: iconColor),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab
                  ? displayWidth(context) * 0.024
                  : displayWidth(context) * 0.055,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab
                  ? displayWidth(context) * 0.014
                  : displayWidth(context) * 0.026,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isTab) {
    return Column(
      children: [
        TextField(
          onChanged: (val) {
            context.read<DashboardBloc>().add(SearchPatients(val));
          },
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab
                ? displayWidth(context) * 0.018
                : displayWidth(context) * 0.032,
          ),
          decoration: InputDecoration(
            hintStyle: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab
                  ? displayWidth(context) * 0.018
                  : displayWidth(context) * 0.032,
            ),
            hintText: "Search by name, ID, phone...",
            prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
            filled: true,
            fillColor: isDark ? darkModeCardColor : lightModeTextFieldBgColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              borderSide: BorderSide(
                color: isDark ? darkModeBorderColor : lightModeBorderColor,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              borderSide: BorderSide(
                color: isDark ? darkModeBorderColor : lightModeBorderColor,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              borderSide: BorderSide(
                color: isDark ? darkModeBorderColor : lightModeBorderColor,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: fieldSpace),
        Row(
          children: [
            Expanded(
              child: CommonDropdown(
                title: "All Status",
                selectedValue: "All",
                options: const [
                  "All",
                  "Active",
                  "Monitoring",
                  "Recovering",
                  "Critical",
                  "Stable",
                ],
                onSelected: (value) {
                  context.read<DashboardBloc>().add(
                    FilterPatients(status: value),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CommonDropdown(
                title: "All Genders",
                selectedValue: "All",
                options: const ["All", "Male", "Female", "Others"],
                onSelected: (value) {
                  context.read<DashboardBloc>().add(
                    FilterPatients(gender: value),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double headerHeight;

  const _StickySearchHeaderDelegate({
    required this.child,
    required this.headerHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => headerHeight;

  @override
  double get minExtent => headerHeight;

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.headerHeight != headerHeight;
  }
}
