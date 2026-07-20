import 'package:flutter/material.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';

class SectionLabelText extends StatelessWidget {
  final String text;
  final bool isTab;

  const SectionLabelText({super.key, required this.text, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);

    return CommonText(
      text,
      style: TextStyle(
        fontFamily: appPoppinFont,
        color: textLightDarkColor,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
      ),
    );
  }
}