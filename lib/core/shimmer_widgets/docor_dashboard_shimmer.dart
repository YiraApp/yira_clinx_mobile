import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DoctorDashboardShimmer extends StatelessWidget {
  final String? fontFamily;

  const DoctorDashboardShimmer({
    super.key,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium, softer shimmer color tones
    final baseColor = isDark ? const Color(0xFF22252A) : const Color(0xFFEBEBEB);
    final highlightColor = isDark ? const Color(0xFF2C3036) : const Color(0xFFF5F5F5);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Card Placeholder
            _buildWelcomeCardShimmer(context, isDark),
            const SizedBox(height: 20.0),

            // 2. Metrics Grid Placeholder
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              childAspectRatio: 1.3,
              children: List.generate(4, (index) => _buildMetricCardShimmer(context, isDark)),
            ),
            const SizedBox(height: 24.0),

            // 3. Section Header Placeholder
            _buildHeaderPlaceholder(),
            const SizedBox(height: 12.0),

            // 4. Appointments Lists Placeholder
            Column(
              children: List.generate(2, (index) => _buildListItemPlaceholder(isDark)),
            ),
            const SizedBox(height: 24.0),

            // 5. Charts Block Placeholder
            _buildChartCardShimmer(context, isDark, barCount: 7), // Weekly representation
            const SizedBox(height: 16.0),
            _buildChartCardShimmer(context, isDark, barCount: 12), // Monthly representation
          ],
        ),
      ),
    );
  }

  // --- BEAUTIFIED COMPONENT BLOCKS ---

  Widget _buildWelcomeCardShimmer(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        // Matching your welcome block styling exactly
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
                Container(width: 80, height: 11, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8.0),
                Container(width: 150, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 12.0),
                Container(width: 200, height: 13, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8.0),
                Container(width: 170, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
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
              Container(width: 55, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ],
          ),
          Container(width: 35, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
          Container(width: 85, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
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
                borderRadius: BorderRadius.circular(12.0) // Matches modern ApponitmentCard avatar styles
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
          // Mocking identical spaceAround bar layouts using structural loops
          SizedBox(
            height: 80, // Matches your original chart sizes beautifully
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                barCount,
                    (index) {
                  // Creates a pretty wave rhythm height calculation so it looks like real charts data loading
                  final double mockHeight = 25.0 + ((index % 3 == 0) ? 45.0 : (index % 2 == 0) ? 20.0 : 35.0);
                  return Container(
                    width: barCount == 7 ? 16 : 10, // Dynamic width matches original monthly (10) and weekly (16) layout parameters
                    height: mockHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)), // Matches your chart design corner radius
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