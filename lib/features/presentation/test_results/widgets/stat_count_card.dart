

import 'package:flutter/material.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';


class StatCountCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const StatCountCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    double cardWidth = (displayWidth(context) - 48) / 2;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonText(
                title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  color: Colors.grey.shade600,
                  fontSize: displayWidth(context)*0.032,
                ),
              ),
              Icon(icon, color: iconColor, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          CommonText(
            count,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context)*0.045,
              fontWeight: FontWeight.w600,
              color: iconColor ,
            ),
          ),
        ],
      ),
    );
  }
}