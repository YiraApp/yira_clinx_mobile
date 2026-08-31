
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class SlotFilterTabs extends StatelessWidget {
  final int selectedIndex;
  final int allCount;
  final int bookedCount;
  final int availableCount;
  final int blockedCount;
  final int breakCount;
  final ValueChanged<int> onTabSelected;
  final bool isTab;

  const SlotFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.allCount,
    required this.bookedCount,
    required this.availableCount,
    this.blockedCount = 0,
    this.breakCount = 0,
    required this.onTabSelected,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      _TabItem(index: 0, label: "All ($allCount)"),
      _TabItem(index: 1, label: "Booked ($bookedCount)"),
      _TabItem(index: 2, label: "Available ($availableCount)"),
      if (blockedCount > 0)
        _TabItem(index: 3, label: "Blocked ($blockedCount)"),
      if (breakCount > 0)
        _TabItem(index: 4, label: "Breaks ($breakCount)"),
    ];

    return Container(
      height: 45,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Row(
        children: tabs.map((tab) => _buildTab(context, tab.index, tab.label)).toList(),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, String label) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (theme.brightness == Brightness.light ? Colors.white : Colors.white24)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(fieldBorderRadius - 2),
            boxShadow: isSelected && theme.brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.026,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : (theme.brightness == Brightness.dark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final int index;
  final String label;
  const _TabItem({required this.index, required this.label});
}