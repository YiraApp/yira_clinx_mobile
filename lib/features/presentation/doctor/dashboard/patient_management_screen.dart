import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_dashboard_bloc/dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/patient_card.dart';
import '../../../../core/common_drop_down/common_drop_down.dart';
import '../../../../core/constants/constants.dart';

class PatientManagementScreen extends StatelessWidget {
  const PatientManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return BlocProvider(
      create: (context) => DashboardBloc()..add(const GetDashboardData()),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: CommonAppBar(
            actions: const [],
            onBackPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: BlocConsumer<DashboardBloc, DashboardState>(
              buildWhen: (previous, state) => state is! ViewPatientDetailsState,
              listener: (context, state) {
                if (state is ViewPatientDetailsState) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.doctorPatientProfileScreen,
                  );
                }
              },
              builder: (context, state) {
                if (state.status == DashboardStatus.loading) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }

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
                                  fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Unified view of patients, medical records, and clinical notes",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Metrics Component Section
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: screenHorizontalSpacePadding,
                          right: screenHorizontalSpacePadding,
                          bottom: fieldSpace,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: SizedBox(
                            height: 110,
                            child: isTab
                                ? Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    context: context,
                                    title: "Total Patients",
                                    value: "3",
                                    icon: Icons.person_outline_rounded,
                                    iconColor: Colors.deepPurpleAccent.withOpacity(0.6),
                                    valueColor: isDark ? Colors.white : Colors.black87,
                                    isTab: isTab,
                                  ),
                                ),
                                const SizedBox(width: fieldSpace),
                                Expanded(
                                  child: _buildMetricCard(
                                    isTab: isTab,
                                    context: context,
                                    title: "Active Cases",
                                    value: "3",
                                    icon: Icons.timeline_rounded,
                                    iconColor: Colors.green.withOpacity(0.6),
                                    valueColor: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: fieldSpace),
                                Expanded(
                                  child: _buildMetricCard(
                                    isTab: isTab,
                                    context: context,
                                    title: "Critical Cases",
                                    value: "0",
                                    icon: Icons.favorite_border_rounded,
                                    iconColor: Colors.redAccent.withOpacity(0.6),
                                    valueColor: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(width: fieldSpace),
                                Expanded(
                                  child: _buildMetricCard(
                                    isTab: isTab,
                                    context: context,
                                    title: "Medical Records",
                                    value: "0",
                                    icon: Icons.description_outlined,
                                    iconColor: Colors.indigoAccent.withOpacity(0.6),
                                    valueColor: Colors.indigo.shade700,
                                  ),
                                ),
                              ],
                            )
                                : ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: _buildMetricCard(
                                    context: context,
                                    title: "Total Patients",
                                    value: "3",
                                    icon: Icons.person_outline_rounded,
                                    iconColor: Colors.deepPurpleAccent.withOpacity(0.6),
                                    valueColor: isDark ? Colors.white : Colors.black87,
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
                                    value: "3",
                                    icon: Icons.timeline_rounded,
                                    iconColor: Colors.green.withOpacity(0.6),
                                    valueColor: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 140,
                                  child: _buildMetricCard(
                                    isTab: isTab,
                                    context: context,
                                    title: "Critical Cases",
                                    value: "0",
                                    icon: Icons.favorite_border_rounded,
                                    iconColor: Colors.redAccent.withOpacity(0.6),
                                    valueColor: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 140,
                                  child: _buildMetricCard(
                                    isTab: isTab,
                                    context: context,
                                    title: "Medical Records",
                                    value: "0",
                                    icon: Icons.description_outlined,
                                    iconColor: Colors.indigoAccent.withOpacity(0.6),
                                    valueColor: Colors.indigo.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 3. PRODUCTION OPTIMIZATION: Sticky persistently pinned header with spacing container padding built-in
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickySearchHeaderDelegate(
                          child: Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                            child: Column(
                              children: [
                                const SizedBox(height: 10), _buildHeader(context, isDark, isTab),
                              ],
                            ),
                          ),
                          headerHeight: isTab ? 140.0 : 130.0,
                        ),
                      ),
                    ];
                  },
                  body: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                    child: state.status == DashboardStatus.success && state.patients.isEmpty
                        ? const Center(
                      child: Text(
                        "No patients found",
                        style: TextStyle(fontFamily: appPoppinFont),
                      ),
                    )
                        : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                      itemCount: state.patients.length,
                      itemBuilder: (context, index) {
                        return PatientCard(
                          isTab: isTab,
                          patient: state.patients[index],
                          onTap: () {
                            context.read<DashboardBloc>().add(
                              ViewPatientDetailsEvent(patientId: '1'),
                            );
                          },
                        );
                      },
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
      padding: EdgeInsets.symmetric(horizontal: isTab ? 10 : 16, vertical: isTab ? 10 : 12),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark ? darkModeBorderColor : lightModeBorderColor,
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.04),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: isTab
          ? Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: iconColor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.045,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.03,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.045,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 20, color: iconColor),
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
            fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
          ),
          decoration: InputDecoration(
            hintStyle: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
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

// =========================================================================
// CUSTOM IMPLEMENTATION: REUSABLE STICKY PERSISTENT SLIVER DELEGATE
// =========================================================================
class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double headerHeight;

  const _StickySearchHeaderDelegate({
    required this.child,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => headerHeight;

  @override
  double get minExtent => headerHeight;

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.headerHeight != headerHeight;
  }
}