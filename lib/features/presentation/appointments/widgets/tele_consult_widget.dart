
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class TeleconsultationCard extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool?> onChanged;
  final bool isDark;
  final bool isTab;

  const TeleconsultationCard({
    super.key,
    required this.isSelected,
    required this.onChanged,
    this.isDark = false, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(fieldBorderRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor.withOpacity(0.8) : Colors.white,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F4FA),
                borderRadius: BorderRadius.circular(fieldBorderRadius),
              ),
              child: const Icon(
                Icons.videocam_outlined,
                color: Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommonText(
                    'Teleconsultation',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize:isTab?displayWidth(context) * 0.02:  displayWidth(context) * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CommonText(
                    maxLines: 2,
                    softWrap: true,
                    'Virtual video call via secure link',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize:isTab?displayWidth(context) * 0.018:  displayWidth(context) * 0.028,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? Colors.blue : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                color: isSelected ? Colors.blue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}