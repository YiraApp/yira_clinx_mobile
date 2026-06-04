import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';

class DetailDisplayCard extends StatelessWidget {
  final String text;

  const DetailDisplayCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: CommonText(
        text,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.032,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
        ),
      ),
    );
  }
}