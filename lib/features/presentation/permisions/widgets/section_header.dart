
import 'package:flutter/material.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontFamily: appPoppinFont,
              fontSize:isTablet(context)?  displayWidth(context)*0.023: displayWidth(context)*0.03,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}