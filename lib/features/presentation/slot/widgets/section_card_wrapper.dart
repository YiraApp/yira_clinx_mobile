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

  const SectionCardWrapper({
    super.key,
    required this.icon,
    required this.title,
    required this.child, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFEAECEF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                ),
                child: Icon(
                  icon,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              CommonText(
                title,
                style:TextStyle(fontFamily: appPoppinFont,
                  fontSize:isTab? displayWidth(context)*0.02 : displayWidth(context)*0.038,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}