import 'package:flutter/material.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart'
    hide textLightModeColor, authFieldBorderColor;
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../core/colors/colors.dart';
import '../../../domain/entities/role/role_entity.dart';

class DialogRoleCard extends StatelessWidget {
  final RoleEntity role;
  final bool isSelected,isTablet;
  final VoidCallback onTap;

  const DialogRoleCard({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap, required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final unselectedCardBg = isDarkMode
        ? theme.cardColor
        : sideMenuDividerColor.withOpacity(1);

    final selectedCardBg = isDarkMode
        ? theme.colorScheme.primaryContainer.withOpacity(0.2)
        : Colors.white;

    final iconBgColor = isDarkMode
        ? theme.scaffoldBackgroundColor
        : (isSelected ? primaryColor.withOpacity(0.2) : Colors.white);

    final titleTextColor = isDarkMode ? Colors.white : textLightModeColor;
    final subtitleTextColor = isDarkMode ? Colors.white60 : textLightDarkColor;

    final iconColor = isSelected
        ? (isDarkMode ? theme.colorScheme.primary : primaryColor)
        : (isDarkMode ? Colors.white70 : scoreSubTextColor);

    final arrowColor = isSelected
        ? (isDarkMode ? theme.colorScheme.primary : textLightDarkColor)
        : (isDarkMode ? Colors.white30 : authFieldBorderColor);

    return GestureDetector(
      onTap: onTap,
      child: isTablet? AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? unselectedCardBg
              : isDarkMode
              ? primaryColor.withOpacity(0.06)
              : unselectedCardBg,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(
            color: isSelected
                ? (isDarkMode
                ? theme.colorScheme.primary
                : primaryColor)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: const [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width * 0.06,
              height: width * 0.06,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                boxShadow: const [],
              ),
              child: Icon(role.icon, color: iconColor, size: width * 0.028),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role.title,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: width * 0.02,
                      fontWeight: FontWeight.w500,
                      color: titleTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.subtitle,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: width * 0.018,
                      fontWeight: FontWeight.w400,
                      color: subtitleTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: arrowColor, size: 16),
          ],
        ),
      ):AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? unselectedCardBg
              : isDarkMode
              ? primaryColor.withOpacity(0.06)
              : unselectedCardBg,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(
            color: isSelected
                ? (isDarkMode
                      ? theme.colorScheme.primary
                      : primaryColor)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: const [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: width * 0.13,
              height: width * 0.13,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                boxShadow: const [],
              ),
              child: Icon(role.icon, color: iconColor, size: width * 0.058),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role.title,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.w600,
                      color: titleTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.subtitle,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: width * 0.029,
                      fontWeight: FontWeight.w600,
                      color: subtitleTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: arrowColor, size: 16),
          ],
        ),
      ),
    );
  }
}
