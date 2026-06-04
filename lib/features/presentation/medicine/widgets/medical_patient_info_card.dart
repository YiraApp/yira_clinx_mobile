
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class MedicalPatientInfoCard extends StatelessWidget {
  final String name;
  final String patientId;

  const MedicalPatientInfoCard({
    super.key,
    required this.name,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTab ? 20.0 : 10.0,
        vertical: isTab ? 16.0 : 10.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isTab ? 28 : 22,
            backgroundColor: primaryColor,
            child: CommonText(
              _getInitials(name),
              style: TextStyle(
                fontFamily: appPoppinFont,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isTab
                    ? displayWidth(context) * 0.016
                    : displayWidth(context) * 0.035,
              ),
            ),
          ),
          SizedBox(width: isTab ? 16 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CommonText(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                    fontSize: isTab
                        ? displayWidth(context) * 0.018
                        : displayWidth(context) * 0.035,
                  ),
                ),
                const SizedBox(height: 4),
                CommonText(
                  patientId,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: appPoppinFont,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.shade600,
                    fontSize: isTab
                        ? displayWidth(context) * 0.014
                        : displayWidth(context) * 0.03,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}