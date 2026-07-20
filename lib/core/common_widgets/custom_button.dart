import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../common_size_helpers/common_size_helpers.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double? width;
  final double height;
  final Widget? icon;
  final bool? noElevation;

  const CustomElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 8.0,
    this.width,
    this.height = 55.0,
    this.icon,
    this.noElevation = false,
  });

  @override
  Widget build(BuildContext context) {
    bool isTab = isTablet(context);
    return isTab
        ? SizedBox(
            width: width ?? double.infinity,
            height: height,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    backgroundColor ?? Theme.of(context).primaryColor,
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                elevation: noElevation! ? 0 : 2,
              ),
              child: icon != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        icon!,
                        const SizedBox(width: 10),
                        Text(
                          text,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: displayWidth(context) * 0.018,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: displayWidth(context) * 0.018,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ),
          )
        : SizedBox(
            width: width ?? double.infinity,
            height: height,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    backgroundColor ?? Theme.of(context).primaryColor,
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                elevation: noElevation! ? 0 : 2,
              ),
              child: icon != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        icon!,
                        const SizedBox(width: 10),
                        Text(
                          text,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: displayWidth(context) * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: displayWidth(context) * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
  }
}
