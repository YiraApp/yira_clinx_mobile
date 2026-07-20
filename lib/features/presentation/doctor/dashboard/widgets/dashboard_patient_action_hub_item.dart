
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../../core/common_widgets/common_text.dart';

class DashBoardPatientActionHubItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool isTab;

  const DashBoardPatientActionHubItem({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isDark
                  ? []
                  : [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          CommonText(
            label,
            style: TextStyle(fontWeight: FontWeight.w500,fontFamily: appPoppinFont,fontSize:isTab? displayWidth(context)*0.018: displayWidth(context)*0.03),
          ),
        ],
      ),
    );
  }
}