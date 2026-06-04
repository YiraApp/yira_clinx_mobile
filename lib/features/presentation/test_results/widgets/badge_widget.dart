

import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../core/common_widgets/common_text.dart';

class TestBadge extends StatelessWidget {
  final String text;
  final Color color;
  const TestBadge({super.key, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: CommonText(
        text,
        style: TextStyle(
          color: color,
          fontFamily: appPoppinFont,
          fontSize: displayWidth(context)*0.022,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}