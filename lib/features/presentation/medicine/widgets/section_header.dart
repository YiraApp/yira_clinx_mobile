import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../core/common_widgets/common_text.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isTab;
  const SectionHeader({super.key, required this.title, required this.isTab});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        CommonText(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: appPoppinFont,
            fontSize:isTab?  displayWidth(context) * 0.02: displayWidth(context) * 0.038,
          ),
        ),
      ],
    );
  }
}
