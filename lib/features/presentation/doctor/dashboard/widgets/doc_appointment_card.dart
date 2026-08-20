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
  final VoidCallback? onStatusTap;
  final bool isTab;
  final bool isTeleConsultation;
  final VoidCallback? onJoinCall;

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
    this.onTap,
    this.onStatusTap,
    required this.isTab,
    this.isTeleConsultation = false,
    this.onJoinCall,
  });

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFFD97706),
      const Color(0xFF0891B2),
      const Color(0xFFDB2777),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? darkModeCardColor : Colors.white;
    final secondaryText = isDark ? textLightDarkColor : scoreSubTextColor;
    final avatarClr = _avatarColor(name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1,
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gradient avatar
                Container(
                  width: isTab ? 48 : 44,
                  height: isTab ? 48 : 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        avatarClr,
                        avatarClr.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.034,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.035,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeOrDate,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.028,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white54 : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white30 : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.028,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  size: 18.0,
                ),
              ],
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.028,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isTeleConsultation)
                  InkWell(
                    onTap: onJoinCall,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            "Join Call",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? displayWidth(context) * 0.012 : 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                GestureDetector(
                  onTap: onStatusTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: isTab ? displayWidth(context) * 0.01 : 10,
                            fontWeight: FontWeight.w700,
                            color: statusTextColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (onStatusTap != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 14,
                            color: statusTextColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}