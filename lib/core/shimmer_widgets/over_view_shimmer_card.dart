import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../config/yira_colors/yira_colors.dart';

class PatientOverviewShimmer extends StatelessWidget {
  const PatientOverviewShimmer({super.key});

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
          children: [
            // 📱 Mobile: Stacked vertically | 💻 Tablet: Side-by-Side Grid Row Structure
            _buildResponsiveRow(
              isTab: isTab,
              children: [
                _buildProfileCardPlaceholder(
                  context,
                  isDark,
                  headerWidth: 140,
                  lineCount: 3,
                  hasEmergencyBox: true,
                ),
                _buildProfileCardPlaceholder(
                  context,
                  isDark,
                  headerWidth: 150,
                  lineCount: 4,
                ),
              ],
            ),
            SizedBox(height: isTab ? 20.0 : 16.0),

            _buildResponsiveRow(
              isTab: isTab,
              children: [
                _buildProfileCardPlaceholder(
                  context,
                  isDark,
                  headerWidth: 110,
                  lineCount: 2,
                ),
                _buildProfileCardPlaceholder(
                  context,
                  isDark,
                  headerWidth: 120,
                  lineCount: 3,
                ),
              ],
            ),
            const SizedBox(height: 80.0), // Padding matching screen bottom constraint
          ],
        ),
      ),
    );
  }

  /// Helper to wrap components dynamically based on screen form factor
  Widget _buildResponsiveRow({required bool isTab, required List<Widget> children}) {
    if (isTab) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((widget) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: widget,
          ),
        )).toList(),
      );
    }

    // Fallback to stacked column for mobile view
    return Column(
      children: [
        children[0],
        const SizedBox(height: 16.0),
        children[1],
      ],
    );
  }

  Widget _buildProfileCardPlaceholder(
      BuildContext context,
      bool isDark, {
        required double headerWidth,
        required int lineCount,
        bool hasEmergencyBox = false,
      }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header Block
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 8.0),
              Container(
                width: headerWidth,
                height: 16,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // Repeating internal item metric list items
          Column(
            children: List.generate(lineCount, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 70,
                            height: 10,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(height: 6.0),
                          Container(
                            width: double.infinity,
                            height: 14,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Matching Highlight Emergency Red Box for the Contact block
          if (hasEmergencyBox) ...[
            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ],
        ],
      ),
    );
  }
}