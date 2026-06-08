import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/common_widgets/common_text.dart';
import '../common_size_helpers/common_size_helpers.dart';

class CommonBorderButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final double? width;
  final double height;
  final Color? borderColor;
  final Color? textColor;
  final bool? isPatientDetail;


  const CommonBorderButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = 42,
    this.borderColor,
    this.textColor, this.isPatientDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color effectiveBorderColor = borderColor ??
        (isDark ? Colors.white24 : Colors.grey.shade300);

    final Color effectiveTextColor = textColor ??
        (isDark ? Colors.white70 : Colors.black87);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isPatientDetail?? false ?8:fieldBorderRadius),
        border: Border.all(color: effectiveBorderColor, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          child: Padding(
            padding: EdgeInsets.only(left: 8,right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: effectiveTextColor),
                  const SizedBox(width: 6),
                ],
                CommonText(
                  text,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize:isTablet(context)?displayWidth(context) * 0.018: displayWidth(context) * 0.035,
                    fontWeight: FontWeight.w500,
                    color: effectiveTextColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}