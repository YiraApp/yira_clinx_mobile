
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/common_drop_down/common_drop_down.dart';
import '../../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/constants/constants.dart';
import '../dashboard_bloc/dashboard_bloc.dart';

class DashboardMetricWidget extends StatelessWidget {
  const DashboardMetricWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: screenHorizontalSpacePadding,
            vertical: fieldSpace,
          ),
          child: Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Patient Management",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Unified view of patients, medical records, and clinical notes",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.03,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
         SliverPadding(
          padding:  EdgeInsets.only(
            left: screenHorizontalSpacePadding,
            right: screenHorizontalSpacePadding,
            bottom: fieldSpace,
          ),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              _buildMetricCard(
                context: context,
                title: "Total Patients",
                value: "3",
                icon: Icons.person_outline_rounded,
                iconColor: Colors.deepPurpleAccent.withOpacity(0.6),
                valueColor: isDark ? Colors.white : Colors.black87,
              ),
              _buildMetricCard(
                context: context,
                title: "Active Cases",
                value: "3",
                icon: Icons.timeline_rounded,
                iconColor: Colors.green.withOpacity(0.6),
                valueColor: Colors.green.shade700,
              ),
              _buildMetricCard(
                context: context,
                title: "Critical Cases",
                value: "0",
                icon: Icons.favorite_border_rounded,
                iconColor: Colors.redAccent.withOpacity(0.6),
                valueColor: Colors.red.shade700,
              ),
              _buildMetricCard(
                context: context,
                title: "Medical Records",
                value: "0",
                icon: Icons.description_outlined,
                iconColor: Colors.indigoAccent.withOpacity(0.6),
                valueColor: Colors.indigo.shade700,
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: screenHorizontalSpacePadding,
            vertical: 10,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildHeader(context, isDark),
          ),
        ),],
    );
  }
  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color valueColor,
  })
  {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey.withOpacity(0.15),
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
      child: Row(
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? Colors.transparent : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          TextField(
            onChanged: (val) {
            },
            decoration: InputDecoration(
              hintStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: displayWidth(context) * 0.032,
              ),
              hintText: "Search by name, ID, phone...",
              prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.0,
                ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.0,
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
      ),
    );
  }
}
