import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';

import '../constants/constants.dart';

class DoctorDashboardShimmer extends StatelessWidget {
  final String? fontFamily;

  const DoctorDashboardShimmer({
    super.key,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = displayWidth(context);
    final bool isTab = isTablet(context);

    final baseColor = isDark ? darkModeCardColor.withOpacity(0.1) : lightModeBaseColor;
    final highlightColor = isDark ? whiteColor.withOpacity(0.08) : darkModeBaseColor;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isTab ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCardShimmer(context, isDark, isTab),
            const SizedBox(height: 20.0),

            // Responsive Metrics Grid
            GridView.count(
              crossAxisCount: isTab ? 4 : 2, // 4 items in a row on tablet, 2 on mobile
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: isTab ? 1.4 : 1.3,
              children: List.generate(4, (index) => _buildMetricCardShimmer(context, isDark)),
            ),
            const SizedBox(height: 24.0),

            if (isTab) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderPlaceholder(),
                        const SizedBox(height: 12.0),
                        ...List.generate(3, (index) => _buildListItemPlaceholder(isDark)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildChartCardShimmer(context, isDark, barCount: 7),
                        const SizedBox(height: 16.0),
                        _buildChartCardShimmer(context, isDark, barCount: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Mobile Layout: Stacked arrangement
              _buildHeaderPlaceholder(),
              const SizedBox(height: 12.0),
              Column(
                children: List.generate(2, (index) => _buildListItemPlaceholder(isDark)),
              ),
              const SizedBox(height: 24.0),
              _buildChartCardShimmer(context, isDark, barCount: 7),
              const SizedBox(height: 16.0),
              _buildChartCardShimmer(context, isDark, barCount: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCardShimmer(BuildContext context, bool isDark, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 28.0 : 20.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C24) : Theme.of(context).primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 11, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
                const SizedBox(height: 8.0),
                Container(width: isTablet ? 250 : 150, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
                const SizedBox(height: 12.0),
                Container(width: isTablet ? 400 : 200, height: 13, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
                const SizedBox(height: 8.0),
                Container(width: isTablet ? 340 : 170, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
              ],
            ),
          ),
          Container(
            width: isTablet ? 56 : 44,
            height: isTablet ? 56 : 44,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          )
        ],
      ),
    );
  }

  Widget _buildMetricCardShimmer(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 55, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
              Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 8.0), // Extra safety spacing for flexible desktop boundaries
          Container(width: 35, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
          Container(width: 85, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
        ],
      ),
    );
  }

  Widget _buildHeaderPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(width: 130, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          Container(width: 55, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  Widget _buildListItemPlaceholder(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 140, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8.0),
                Container(width: 90, height: 11, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCardShimmer(BuildContext context, bool isDark, {required int barCount}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 12.0), // Unified bottom spacing for row-wrapping edge cases
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              Container(width: 65, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            ],
          ),
          const SizedBox(height: 32.0),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                barCount,
                    (index) {
                  final double mockHeight = 25.0 + ((index % 3 == 0) ? 45.0 : (index % 2 == 0) ? 20.0 : 35.0);
                  return Container(
                    width: barCount == 7 ? 16 : 10,
                    height: mockHeight,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}