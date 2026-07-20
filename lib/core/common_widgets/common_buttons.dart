

import 'package:flutter/material.dart';

class CommonButtons {
  static Widget getTextButtonWithUnderLineContactUs(
      String title,
      BuildContext context,
      Color textColor,
      double textSize,
      bool isClickLink,
      FontWeight fontWeight,
      IconData icon,
      Function()? onTap) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center, // Ensures no extra space
        children: [
          Icon(icon, color: textColor, size: 14),
          SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: textSize,
              color: textColor,
              fontWeight: fontWeight,
              decorationColor: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static Widget getTextButton(
      String title,
      BuildContext context,
      Color textColor,
      double textSize,
      bool isClickLink,
      FontWeight fontWeight,
      Function()? onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        title,
        style: isClickLink
            ? TextStyle(
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dashed,
            fontSize: textSize,
            color: textColor,
            fontWeight: fontWeight)
            : TextStyle(
            fontSize: textSize, color: textColor, fontWeight: fontWeight),
      ),
    );
  }
}