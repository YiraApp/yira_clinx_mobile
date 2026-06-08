import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../../core/common_widgets/common_text.dart';

class DashBoardPatientVitalTile extends StatelessWidget {
  final String label;
  final String? value;
  final String unit;
  final IconData icon;
  final Color themeColor;

  const DashBoardPatientVitalTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? themeColor.withOpacity(0.08)
            : themeColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark
              ? themeColor.withOpacity(0.2)
              : themeColor.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: themeColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: CommonText(
                  label,
                  style: TextStyle(
                    color: themeColor,
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                    fontSize: displayWidth(context) * 0.029,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              CommonText(
                value ?? '--',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: displayWidth(context) * 0.032,
                  fontFamily: appPoppinFont,
                ),
              ),
              const SizedBox(width: 4),
              CommonText(
                unit,
                style: TextStyle(color: Colors.grey,fontSize: displayWidth(context) * 0.03,
                  fontFamily: appPoppinFont,),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
