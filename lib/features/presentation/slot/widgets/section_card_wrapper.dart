import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class SectionCardWrapper extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool isTab;
  final Widget? trailing;

  const SectionCardWrapper({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    required this.isTab,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with subtle gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [primaryColor.withValues(alpha: 0.08), Colors.transparent]
                    : [primaryColor.withValues(alpha: 0.04), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: CommonText(
                    title,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.038,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: child,
          ),
        ],
      ),
    );
  }
}