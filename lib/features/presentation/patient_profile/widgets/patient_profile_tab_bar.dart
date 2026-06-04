
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class PatientProfileTabBar extends StatefulWidget {
  final List<String> tabs;
  final Function(int) onTabSelected;

  const PatientProfileTabBar({
    super.key,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  State<PatientProfileTabBar> createState() => _PatientProfileTabBarState();
}

class _PatientProfileTabBarState extends State<PatientProfileTabBar> {
  int _activeTabIdx = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.tabs.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, idx) {
          final isActive = _activeTabIdx == idx;
          final activeBgColor = primaryColor.withOpacity(0.15);
          final activeTextColor = isDark ? Colors.blue[300]! : const Color(0xFF1A73E8);
          final inactiveTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

          return GestureDetector(
            onTap: () {
              setState(() => _activeTabIdx = idx);
              widget.onTabSelected(idx);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? activeBgColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  widget.tabs[idx],
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.032,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}