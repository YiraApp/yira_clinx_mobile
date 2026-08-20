import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../core/colors/colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String count;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isTab;

  const StatCard({
    super.key,
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  darkModeCardColor,
                  darkModeCardColor.withOpacity(0.8),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  iconColor.withOpacity(0.03),
                ],
              ),
        border: Border.all(
          width: 1,
          color: isDark
              ? iconColor.withOpacity(0.15)
              : iconColor.withOpacity(0.12),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: iconColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withOpacity(isDark ? 0.2 : 0.12),
                      iconColor.withOpacity(isDark ? 0.08 : 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: isTab ? 16 : 14, color: iconColor),
              ),
              Text(
                count,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w700,
                  fontSize: isTab
                      ? displayWidth(context) * 0.022
                      : displayWidth(context) * 0.05,
                  color: iconColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w600,
                  fontSize: isTab
                      ? displayWidth(context) * 0.015
                      : displayWidth(context) * 0.03,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w400,
                  fontSize: isTab
                      ? displayWidth(context) * 0.013
                      : displayWidth(context) * 0.024,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}