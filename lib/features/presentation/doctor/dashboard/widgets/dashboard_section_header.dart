import 'package:flutter/material.dart';

import '../../../../../core/common_size_helpers/common_size_helpers.dart';

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final String? countBadge;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;
  final bool isTab;
  final String fontFamily;

  const DashboardSectionHeader({
    super.key,
    required this.title,
    required this.actionText,
    this.countBadge,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
    required this.isTab,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: isTab ? displayWidth(context) * 0.02 : 16.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            if (countBadge != null && countBadge!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  countBadge!,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: isTab ? 12 : 11,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: isTab ? displayWidth(context) * 0.016 : 13,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: isTab ? 16 : 15,
                  color: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}