
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../colors/colors.dart';
import '../constants/constants.dart';

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

class ValueShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ValueShimmer({
    super.key,
    this.width = 60,
    this.height = 14,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BaseShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
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
        color: isDark ? darkModeWelcomeCardColor: Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
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

class MetricCardShimmer extends StatelessWidget {
  const MetricCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
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
        borderRadius: BorderRadius.circular(fieldBorderRadius),
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
            Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
          ],
        ),
      ),
    );
  }
}

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
                Container(width: 70, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(fieldBorderRadius))),
              ],
            ),
            const SizedBox(height: 32.0),
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

class PatientProfileScreenShimmer extends StatelessWidget {
  final bool isDark;
  final bool isTab;

  const PatientProfileScreenShimmer({
    super.key,
    required this.isDark,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? darkModeCardColor.withOpacity(0.15) : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.white.withOpacity(0.08) : darkModeBaseColor;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                        Container(
                          width: 80,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 140, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(height: 6),
                              Container(width: 180, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(width: 60, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 12),
                                  Container(width: 100, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(isTab ? 5 : 4, (index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 75,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(fieldBorderRadius),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(height: 6),
                              Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListCardShimmer extends StatelessWidget {
  final int itemCount;
  const ListCardShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 8),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: BaseShimmer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 160, height: 14, color: Colors.white),
                      const SizedBox(height: 10),
                      Container(width: 220, height: 10, color: Colors.white),
                      const SizedBox(height: 14),
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(fieldBorderRadius),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ClinicalNotesShimmer extends StatelessWidget {
  final int itemCount;
  const ClinicalNotesShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 8),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: BaseShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 140, height: 12, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 14),
                Container(width: double.infinity, height: 12, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: 200, height: 12, color: Colors.white),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 100, height: 10, color: Colors.white),
                    Container(
                      width: 32,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


