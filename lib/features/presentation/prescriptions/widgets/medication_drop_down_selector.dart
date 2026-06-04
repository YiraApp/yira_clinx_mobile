import 'package:flutter/material.dart';

import '../../../../config/yira_colors/yira_colors.dart';
import '../../../../core/colors/colors.dart' hide lightModeTextFieldBgColor;
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class MedicationDropdownSelector extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const MedicationDropdownSelector({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasValidValue = items.contains(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonText(
          label,
          style: TextStyle(
            letterSpacing: 0.5,
            fontFamily: appPoppinFont,
            fontSize: displayWidth(context) * 0.033,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light
                ? lightModeTextFieldBgColor
                : darkModeFieldBgColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: hasValidValue ? value : null,
              isExpanded: true,
              // 🚀 FIX 1: Ensures the popup surface matches the text field theme styling
              dropdownColor: theme.brightness == Brightness.light
                  ? lightModeTextFieldBgColor
                  : theme.colorScheme.surface,
              hint: CommonText(
                'Select',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.normal,
                  fontSize: displayWidth(context) * 0.034,
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: items.map((String item) {
                return DropdownMenuItem<String>(

                  value: item,
                  child: CommonText(
                    item,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.normal,
                      fontSize: displayWidth(context) * 0.035,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}