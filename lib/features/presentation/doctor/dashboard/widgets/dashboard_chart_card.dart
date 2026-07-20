import 'package:flutter/material.dart';
import '../../../../../core/colors/colors.dart';
import '../../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/constants/constants.dart';

class DashboardChartCard extends StatelessWidget {
  final String title;
  final String badgeText;
  final bool isDark;
  final Widget chartContent;
  final bool isTab;
  final String fontFamily;

  const DashboardChartCard({
    super.key,
    required this.title,
    required this.badgeText,
    required this.isDark,
    required this.chartContent,
    required this.isTab,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(width: 0.5, color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.036,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800]!.withOpacity(0.5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.026,
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          chartContent,
        ],
      ),
    );
  }
}