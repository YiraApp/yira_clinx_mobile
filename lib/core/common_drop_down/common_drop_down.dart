import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../colors/colors.dart';
import '../common_widgets/common_text.dart';

class CommonDropdown extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedValue;
  final Function(String) onSelected;
  final double? borderRadius;

  const CommonDropdown({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
    required this.onSelected,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    // Safe fallback logic for border radius matching the text field
    final double computedRadius = borderRadius ?? fieldBorderRadius ?? 8.0;

    // Adaptive Border & Surface Color Matrices using your constant variables
    final Color inactiveBorderColor = isDark ? darkModeBorderColor : lightModeBorderColor;
    final Color surfaceColor = isDark
        ? darkModeCardColor.withOpacity(0.8)
        : lightModeTextFieldBgColor;

    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      offset: const Offset(0, 48), // Adjusted offset slightly for a clean dropdown alignment
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(computedRadius)),
      itemBuilder: (context) => options.map((String option) {
        return PopupMenuItem<String>(
          value: option,
          child: CommonText(
            option,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Synchronized with text fields
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(computedRadius),
          // --- Clean Constants Mapping Matrix ---
          border: Border.all(
            color: inactiveBorderColor,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CommonText(
                selectedValue ?? title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                  fontWeight: selectedValue != null ? FontWeight.w500 : FontWeight.w400,
                  color: selectedValue != null
                      ? (isDark ? Colors.white : textLightModeColor)
                      : (isDark ? Colors.white.withOpacity(0.5) : textLightModeColor.withOpacity(0.5)),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}