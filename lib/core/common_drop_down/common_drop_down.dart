
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

  const CommonDropdown({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
      itemBuilder: (context) => options.map((String option) {
        return PopupMenuItem<String>(
          value: option,
          child: CommonText(
            option,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.032,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: isDark? darkModeCardColor:Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child:CommonText(
                selectedValue ?? title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: displayWidth(context) * 0.032,
                  fontWeight: selectedValue != null ? FontWeight.w600 : FontWeight.w400,
                  color: selectedValue != null
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                      : Colors.grey,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}