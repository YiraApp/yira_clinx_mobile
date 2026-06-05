
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';

class VitalSignTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color accentColor;

  const VitalSignTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonText(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              color: accentColor,
              fontWeight: FontWeight.w700,
              fontSize: isTab ? displayWidth(context) * 0.012 : displayWidth(context) * 0.028,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CommonText(
                value,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w500,
                  fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.032,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                CommonText(
                  unit!,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                    fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.032,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}