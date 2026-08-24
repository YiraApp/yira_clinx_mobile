import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class DocMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final String? badgeText;
  final IconData icon;
  final Color iconColor;
  final double? progressValue;
  final VoidCallback? onTap;
  final bool isTab;
  final double? height;

  const DocMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtext,
    this.badgeText,
    required this.icon,
    required this.iconColor,
    this.progressValue,
    this.onTap,
    required this.isTab,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardHeight = height ?? (isTab ? 165.0 : 144.0);

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          width: 1.2,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.all(isTab ? 18.0 : 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Icon Container + Badge / Action Arrow
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Vibrant Glowing Icon Container
                    Container(
                      padding: EdgeInsets.all(isTab ? 10 : 8.5),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: isTab ? 22.0 : 19.0,
                      ),
                    ),

                    // Badge Pill or Tap Chevron
                    if (badgeText != null && badgeText!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: iconColor.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 12 : 10.5,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      )
                    else if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                  ],
                ),

                // Middle: Large Bold Value
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 28 : 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),

                // Bottom: Title + Subtext (or progress line)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 14 : 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    if (progressValue != null && progressValue! >= 0) ...[
                      const SizedBox(height: 3.0),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue!.clamp(0.0, 1.0),
                          backgroundColor: iconColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                          minHeight: 3.5,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                    ] else
                      Text(
                        subtext,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 12 : 10.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.1,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
