import 'package:flutter/material.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class MedicationDropdownSelector extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double? borderRadius;

  const MedicationDropdownSelector({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    final double computedRadius = fieldBorderRadius;

    final Color inactiveBorderColor = isDark ? darkModeBorderColor : lightModeBorderColor;
    final Color surfaceColor = isDark
        ? darkModeCardColor.withOpacity(0.9)
        : lightModeTextFieldBgColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          CommonText(
            label,
            style: TextStyle(
              letterSpacing: 0.5,
              fontFamily: appPoppinFont,
              fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.033,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
        ],

        LayoutBuilder(
          builder: (context, constraints) {
            return PopupMenuButton<String>(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth > 0 ? constraints.maxWidth : 200,
              ),
              onSelected: (String newValue) => onChanged(newValue),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              offset: const Offset(0, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(computedRadius)),
              itemBuilder: (context) => items.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: CommonText(
                    item,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(computedRadius),
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
                        (value != null && value!.isNotEmpty) ? value! : 'Select',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                          fontWeight: (value != null && value!.isNotEmpty) ? FontWeight.w500 : FontWeight.w400,
                          color: (value != null && value!.isNotEmpty)
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
          },
        ),
      ],
    );
  }
}