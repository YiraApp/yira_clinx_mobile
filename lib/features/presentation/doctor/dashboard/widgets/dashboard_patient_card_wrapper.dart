import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/common_widgets/common_text.dart';

class DashBoardPatientDetailCardWrapper extends StatelessWidget {
  final Widget child;
  final String title;
  final bool isTab;

  const DashBoardPatientDetailCardWrapper({
    super.key,
    required this.child,
    required this.title,required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: screenHorizontalSpacePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            title,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w500,
              fontSize:isTab? displayWidth(context) * 0.02: displayWidth(context)*0.035,
            ),
          ),
          const SizedBox(height: titleSpace),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}