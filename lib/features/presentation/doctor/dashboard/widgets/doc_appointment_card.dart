import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart' hide textLightModeColor;
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../../core/colors/colors.dart';

class DocAppointmentCard extends StatelessWidget {
  final String initials;
  final String name;
  final String subtitle;
  final String description;
  final String timeOrDate;
  final String statusLabel;
  final Color statusColor;
  final Color statusTextColor;
  final VoidCallback? onTap;
  final bool isTab;

  const DocAppointmentCard({
    super.key,
    required this.initials,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.timeOrDate,
    required this.statusLabel,
    required this.statusColor,
    required this.statusTextColor,
    this.onTap, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? darkModeCardColor : Colors.white;
    final borderSurface = isDark ? const Color(0xFF334155) : sideMenuDividerColor;
    final primaryText = isDark ? Colors.white : textLightModeColor;
    final secondaryText = isDark ? textLightDarkColor : scoreSubTextColor;

    return Container(
      margin: const EdgeInsets.only(bottom: fieldSpace),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(width: 0.5,color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        child: Column(
          crossAxisAlignment: .end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark ? statusTextColor.withOpacity(0.12) : statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize:isTab? displayWidth(context)*0.018: displayWidth(context)*0.035,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : statusTextColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: fieldSpace),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize:isTab? displayWidth(context)*0.018: displayWidth(context)*0.035,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeOrDate,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab? displayWidth(context)*0.016:displayWidth(context)*0.03,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize:isTab? displayWidth(context)*0.016: displayWidth(context)*0.03,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        description,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab? displayWidth(context)*0.016:displayWidth(context)*0.03,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  size: 16.0,
                ),
              ],
            ),
            SizedBox(height: 5,),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                statusLabel.toUpperCase(),
                style: TextStyle(
                  fontSize:isTab? displayWidth(context)*0.01: 10,
                  fontWeight: FontWeight.w800,
                  color: statusTextColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}