


import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';

import '../../../../core/constants/constants.dart';

class PatientInfoCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Widget child;
  final bool isTab;

  const PatientInfoCard({
    Key? key,
    required this.title,
    required this.titleIcon,
    required this.child, required this.isTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: screenHorizontalSpacePadding,right: screenHorizontalSpacePadding, top: 0,bottom: fieldSpace),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Icon(
                titleIcon,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w500,
                  fontSize:isTab? displayWidth(context)*0.02: displayWidth(context)*0.035,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}