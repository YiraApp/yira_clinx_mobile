import 'package:flutter/material.dart';

import '../../../../../core/common_size_helpers/common_size_helpers.dart';

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;
  final bool isTab;
  final String fontFamily;

  const DashboardSectionHeader({
    super.key,
    required this.title,
    required this.actionText,
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
        Text(
          title,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.038,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onTap,
          child: Text(
            actionText,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}