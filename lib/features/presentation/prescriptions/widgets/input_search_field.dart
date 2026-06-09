import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_widgets/common_text.dart';

class InputSearchChipField extends StatelessWidget {
  final String title;
  final String subtitle;
  final String hintText;
  final IconData icon;
  final List<String> selectedTokens;
  final Function(String) onRemoveToken;
  final ValueChanged<String>? onSubmitted;
  final bool isTab;

  const InputSearchChipField({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hintText,
    required this.icon,
    required this.selectedTokens,
    required this.onRemoveToken,
    this.onSubmitted, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.primaryColor, size: 18),
            const SizedBox(width: 8),
            CommonText(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: appPoppinFont,
                fontSize:isTab
                    ? displayWidth(context) * 0.02: displayWidth(context) * 0.038,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 4, bottom: 12),
          child: CommonText(
            subtitle,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: appPoppinFont,
              fontSize:isTab
                  ? displayWidth(context) * 0.018: displayWidth(context) * 0.028,
              color: Colors.grey,
            ),
            maxLines: 2,
            softWrap: true,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:isDarkMode? darkModeCardColor.withOpacity(0.9)  :Colors.transparent,
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedTokens.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: selectedTokens.map((token) {
                    return InputChip(
                      label: CommonText(
                        token,
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontFamily: appPoppinFont,
                          fontSize:isTab
                              ? displayWidth(context) * 0.018: displayWidth(context) * 0.03,
                        ),
                      ),
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      onDeleted: () => onRemoveToken(token),
                      deleteIconColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          fieldBorderRadius / 2,
                        ),
                      ),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                onSubmitted: onSubmitted,
                style: TextStyle(
                  decorationThickness: 0,
                  decoration: TextDecoration.none,
                  fontFamily: appPoppinFont,
                  fontSize: isTab
                      ? displayWidth(context) * 0.018:displayWidth(context) * 0.032,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    decorationThickness: 0,
                    decoration: TextDecoration.none,
                    color: Colors.grey,
                    fontFamily: appPoppinFont,
                    fontSize: isTab
                        ? displayWidth(context) * 0.018:displayWidth(context) * 0.03,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
