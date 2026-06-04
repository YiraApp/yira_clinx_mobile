import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../common_widgets/common_text.dart';

class CustomMenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? customColor;
  final double? parentWidth;

  const CustomMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.customColor,
    this.parentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isTab = isTablet(context);

   final double referenceWidth = parentWidth ?? (isTab ? 360 : displayWidth(context));

    final Color activeBgColor = theme.primaryColor;
    final Color activeTextColor = Colors.white;
    final Color inactiveTextColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: referenceWidth * 0.045,
        vertical: 4.0,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: referenceWidth * 0.045,
            vertical: referenceWidth * 0.038,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(fieldBorderRadius),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: customColor ?? (inactiveTextColor.withOpacity(0.7)),
                size: referenceWidth * (isTab ? 0.048 : 0.045),
              ),
              SizedBox(width: referenceWidth * 0.045),
              Expanded(
                child: CommonText(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    color: customColor ?? ( inactiveTextColor),
                    fontSize: referenceWidth * (isTab ? 0.042 : 0.033),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}