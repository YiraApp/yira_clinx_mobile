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
    final bool isTab = isTablet(context);

    final baseColor = isDark ? darkModeCardColor.withValues(alpha: 0.1) : lightModeBaseColor;
    final highlightColor = isDark ? whiteColor.withValues(alpha: 0.08) : darkModeBaseColor;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 12.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsLayout(context, isDark, isTab),
            const SizedBox(height: 20.0),

            const _HeaderPlaceholder(),
            const SizedBox(height: 10.0),
            Column(
              children: List.generate(
                isTab ? 3 : 2,
                (index) => _ListItemPlaceholder(isDark: isDark),
              ),
            ),
            const SizedBox(height: 20.0),

            _buildChartCardShimmer(context, isDark, barCount: 7),
            const SizedBox(height: 14.0),
            _buildChartCardShimmer(context, isDark, barCount: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsLayout(BuildContext context, bool isDark, bool isTab) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(width: 8),
                    Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
                Container(width: 80, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[100]),
          if (isTab)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildMetricItemShimmer(),
                    ),
                  );
                }),
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Padding(padding: const EdgeInsets.all(14), child: _buildMetricItemShimmer())),
                    Container(width: 1, height: 90, color: isDark ? Colors.grey[800] : Colors.grey[100]),
                    Expanded(child: Padding(padding: const EdgeInsets.all(14), child: _buildMetricItemShimmer())),
                  ],
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey[100]),
                Row(
                  children: [
                    Expanded(child: Padding(padding: const EdgeInsets.all(14), child: _buildMetricItemShimmer())),
                    Container(width: 1, height: 90, color: isDark ? Colors.grey[800] : Colors.grey[100]),
                    Expanded(child: Padding(padding: const EdgeInsets.all(14), child: _buildMetricItemShimmer())),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMetricItemShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 10),
        Container(width: 45, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 4),
        Container(width: 75, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
      ],
    );
  }

  Widget _buildChartCardShimmer(BuildContext context, bool isDark, {required int barCount}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
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
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                barCount,
                    (index) {
                  final double mockHeight = 30.0 + ((index % 3 == 0) ? 55.0 : (index % 2 == 0) ? 25.0 : 40.0);
                  return Container(
                    width: barCount == 7 ? 18 : 12,
                    height: mockHeight,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
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

// =========================================================================
// PERFORMANCE OPTIMIZATIONS: EXTRACTED CONST WIDGETS
// =========================================================================

class _HeaderPlaceholder extends StatelessWidget {
  const _HeaderPlaceholder();

  @override
  Widget build(BuildContext context) {
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
}

class _ListItemPlaceholder extends StatelessWidget {
  final bool isDark;

  const _ListItemPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
}