import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class ProfileStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isTab;

  const ProfileStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTab ? 12 : 10,
          vertical: isTab ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.12),
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: isTab ? 18 : 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab
                    ? displayWidth(context) * 0.018
                    : displayWidth(context) * 0.036,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab
                    ? displayWidth(context) * 0.012
                    : displayWidth(context) * 0.024,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
