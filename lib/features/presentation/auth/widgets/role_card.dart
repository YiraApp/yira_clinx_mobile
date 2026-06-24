import 'package:flutter/material.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart'
    hide textLightModeColor, authFieldBorderColor;
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../core/colors/colors.dart';
import '../../../domain/entities/login/login_entity.dart';
import '../../../domain/entities/role/role_entity.dart';

class DialogRoleCard extends StatelessWidget {

  final bool isSelected, isTablet;
  final VoidCallback onTap;
final RoleEntity roleEntity;
  const DialogRoleCard({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.isTablet, required this.roleEntity,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final unselectedCardBg = isDarkMode
        ? theme.cardColor
        : sideMenuDividerColor.withOpacity(1);

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

    final double iconBoxSize = isTablet ? (width * 0.06) : (width * 0.13);
    final double iconSize = isTablet ? (width * 0.028) : (width * 0.058);

    final double titleFontSize = isTablet ? (width * 0.02) : (width * 0.04);
    final FontWeight titleFontWeight = isTablet ? FontWeight.w500 : FontWeight.w600;

    final double subtitleFontSize = isTablet ? (width * 0.018) : (width * 0.029);
    final FontWeight subtitleFontWeight = isTablet ? FontWeight.w400 : FontWeight.w600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
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
                ? (isDarkMode ? theme.colorScheme.primary : primaryColor)
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: const [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                boxShadow: const [],
              ),
              child: Icon(Icons.person, color: iconColor, size: iconSize),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    roleEntity.roleName ?? '',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: titleFontSize,
                      fontWeight: titleFontWeight,
                      color: titleTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                     'Authorised access',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: subtitleFontSize,
                      fontWeight: subtitleFontWeight,
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