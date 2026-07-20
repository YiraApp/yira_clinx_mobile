
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class SlotFilterTabs extends StatelessWidget {
  final int selectedIndex;
  final int allCount;
  final int bookedCount;
  final int availableCount;
  final ValueChanged<int> onTabSelected;
  final bool isTab;

  const SlotFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.allCount,
    required this.bookedCount,
    required this.availableCount,
    required this.onTabSelected, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: isDark
            ? darkModeCardColor
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Row(
        children: [
          _buildTab(context, 0, "All ($allCount)"),
          _buildTab(context, 1, "Booked ($bookedCount)"),
          _buildTab(context, 2, "Available ($availableCount)"),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, String label) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (theme.brightness == Brightness.light ? Colors.white : Colors.white70)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            boxShadow: isSelected && theme.brightness == Brightness.light
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context)*0.03,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}