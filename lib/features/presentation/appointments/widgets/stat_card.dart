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
    required this.iconColor, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        color: isDark?darkModeCardColor:Colors.white,
        border: Border.all(width: 0.5,color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distributes text evenly vertically
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w600,
              fontSize:isTab? displayWidth(context)*0.018: displayWidth(context)*0.032
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w600,
                fontSize:isTab? displayWidth(context)*0.02: displayWidth(context)*0.045,
              color: iconColor
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.normal,
                    fontSize: isTab? displayWidth(context)*0.015:displayWidth(context)*0.025,),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 15, color: iconColor),
            ],
          )
        ],
      ),
    );
  }
}