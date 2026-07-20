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

    final baseColor = isDark ? darkModeCardColor.withOpacity(0.1) : lightModeBaseColor;
    final highlightColor = isDark ? whiteColor.withOpacity(0.08) : darkModeBaseColor;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(isTab ? 24.0 : 16.0),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCardShimmer(context, isDark, isTab),
            const SizedBox(height: 20.0),

            _buildMetricsLayout(context, isDark, isTab),
            const SizedBox(height: 24.0),

            const _HeaderPlaceholder(),
            const SizedBox(height: 16.0),
            Column(
              children: List.generate(
                isTab ? 3 : 2,
                    (index) => _ListItemPlaceholder(isDark: isDark),
              ),
            ),
            const SizedBox(height: 20.0),

            const _HeaderPlaceholder(),
            const SizedBox(height: 16.0),
            Column(
              children: List.generate(
                isTab ? 3 : 2,
                    (index) => _ListItemPlaceholder(isDark: isDark),
              ),
            ),
            const SizedBox(height: 24.0),

            _buildChartCardShimmer(context, isDark, barCount: 7),
            const SizedBox(height: 20.0),
            _buildChartCardShimmer(context, isDark, barCount: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsLayout(BuildContext context, bool isDark, bool isTab) {
    if (isTab) {
      return Row(
        children: List.generate(4, (index) {
          final bool isLast = index == 3;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0.0 : 16.0),
              child: _MetricCardShimmer(isDark: isDark),
            ),
          );
        }),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 1.35,
        children: List.generate(4, (index) => _MetricCardShimmer(isDark: isDark)),
      );
    }
  }

  Widget _buildWelcomeCardShimmer(BuildContext context, bool isDark, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C24) : Theme.of(context).primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.0),
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

class _MetricCardShimmer extends StatelessWidget {
  final bool isDark;

  const _MetricCardShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
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
              Container(width: 55, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
              Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ],
          ),
          // PRODUCTION FIX: Removed `Spacer()` to prevent crash within unbounded scroll-view constraints.
          // Replaced with a reliable spacing block to position lower rows perfectly.
          const SizedBox(height: 16.0),
          Container(width: 35, height: 26, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
          const SizedBox(height: 6.0),
          Container(width: 85, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
        ],
      ),
    );
  }
}

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