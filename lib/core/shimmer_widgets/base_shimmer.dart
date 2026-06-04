
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BaseShimmer extends StatelessWidget {
  final Widget child;

  const BaseShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: child,
    );
  }
}

class WelcomeCardShimmer extends StatelessWidget {
  const WelcomeCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C24) : Colors.white,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: BaseShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 80, height: 11, color: Colors.white),
                  const SizedBox(height: 6.0),
                  Container(width: 160, height: 24, color: Colors.white),
                  const SizedBox(height: 12.0),
                  Container(width: 220, height: 13, color: Colors.white),
                  const SizedBox(height: 8.0),
                  Container(width: 180, height: 12, color: Colors.white),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            )
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a single Metric Grid item
class MetricCardShimmer extends StatelessWidget {
  const MetricCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: BaseShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 60, height: 14, color: Colors.white),
                Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ],
            ),
            Container(width: 40, height: 28, color: Colors.white),
            Container(width: 80, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for Appointment and Patient List tiles
class AppointmentCardShimmer extends StatelessWidget {
  const AppointmentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: BaseShimmer(
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, color: Colors.white),
                  const SizedBox(height: 6.0),
                  Container(width: 80, height: 12, color: Colors.white),
                ],
              ),
            ),
            Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for both Weekly and Monthly charts
class ChartCardShimmer extends StatelessWidget {
  const ChartCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: BaseShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 140, height: 16, color: Colors.white),
                Container(width: 70, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              ],
            ),
            const SizedBox(height: 32.0),
            // Mocking a bar chart look inside the shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final mockHeights = [60.0, 90.0, 30.0, 75.0, 45.0, 80.0, 20.0];
                return Container(
                  width: 16,
                  height: mockHeights[index],
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Combines all pieces into a beautiful structural skeleton layout matching your screen
class DoctorDashboardSkeleton extends StatelessWidget {
  const DoctorDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WelcomeCardShimmer(),
          const SizedBox(height: 20.0),

          // Metrics Grid Skeleton
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 1.3,
            children: const [
              MetricCardShimmer(),
              MetricCardShimmer(),
              MetricCardShimmer(),
              MetricCardShimmer(),
            ],
          ),
          const SizedBox(height: 24.0),

          // Schedule Section Skeleton
          Container(width: 150, height: 18, color: Colors.grey[400]),
          const SizedBox(height: 12.0),
          const AppointmentCardShimmer(),
          const AppointmentCardShimmer(),

          const SizedBox(height: 24.0),

          // Chart Skeleton
          const ChartCardShimmer(),
        ],
      ),
    );
  }
}


