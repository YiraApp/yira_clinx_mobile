import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import '../../../../config/yira_colors/yira_colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../../upload_documnets/model/app_pop_up_model.dart';
import '../../upload_documnets/widgets/common_custom_pop_up_menu.dart';

class SinglePrescriptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
final bool isTab;
  const SinglePrescriptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    this.onEdit, this.onDelete, this.onView, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    final Color primaryTeal = theme.primaryColor;
    final Color iconColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        right: screenHorizontalSpacePadding,
        left: screenHorizontalSpacePadding,
        bottom: fieldSpace,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [darkModeCardColor, darkModeCardColor.withOpacity(0.85)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(fieldBorderRadius), // Smoother premium border rounding
        boxShadow: !isDark
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            spreadRadius: 0,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: primaryTeal.withOpacity(0.02),
            spreadRadius: -4,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200.withOpacity(0.6),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        child: InkWell(
          onTap: () {},
          splashColor: primaryTeal.withOpacity(0.04),
          highlightColor: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryTeal.withOpacity(isDark ? 0.06 : 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 24,
                bottom: 24,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: primaryTeal.withOpacity(0.7),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(fieldBorderRadius),
                      bottomRight: Radius.circular(fieldBorderRadius),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 4),
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFE8F5E9).withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFC8E6C9).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.science_rounded,
                        color: iconColor,
                        size: isTab ? 26 : 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          CommonText(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: displayWidth(context) * (isTab ? 0.018 : 0.035),
                              fontWeight: FontWeight.w500,
                              color: isDark ? sideMenuDividerColor : cardPopUpMenuColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          CommonText(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: displayWidth(context) * (isTab ? 0.015 : 0.03),
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                              color: isDark ? textLightDarkColor : scoreSubTextColor,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.02) : sideMenuDividerColor,
                              borderRadius: BorderRadius.circular(fieldBorderRadius),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.02) : deviderColor,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: isTab ? 13 : 11,
                                  color: isDark ? scoreSubTextColor : textLightDarkColor,
                                ),
                                const SizedBox(width: 6),
                                CommonText(
                                  date.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: displayWidth(context) * (isTab ? 0.012 : 0.026),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                    color: isDark ? textLightDarkColor : dialogueSubTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    CommonCustomPopupMenu(
                      items: [
                        if (onView != null)
                          AppPopupItemModel(
                            icon: Icons.visibility_outlined,
                            title: 'View Details',
                            onTap: onView!,
                          ),
                        if (onEdit != null)
                          AppPopupItemModel(
                            icon: Icons.edit_outlined,
                            title: 'Edit',
                            onTap: onEdit!,
                          ),
                        if (onDelete != null)
                          AppPopupItemModel(
                            icon: Icons.delete_outline_rounded,
                            title: 'Delete',
                            onTap: onDelete!,
                            isDestructive: true,
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: theme.appBarTheme.iconTheme?.color ?? (isDark ? Colors.white70 : Colors.black54),
                          size: 18,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}