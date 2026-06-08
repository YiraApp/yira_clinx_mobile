
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../../core/common_widgets/common_text.dart';

class ClinicalNoteItemTile extends StatelessWidget {
  final String doctorName;
  final String date;
  final String text;

  const ClinicalNoteItemTile({
    super.key,
    required this.doctorName,
    required this.date,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonText(
                doctorName,
                style:  TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: displayWidth(context)*0.033,
                  fontFamily: appPoppinFont
                ),
              ),
              CommonText(
                date,
                style:TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: displayWidth(context)*0.028,
                    fontFamily: appPoppinFont
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          CommonText(
            text,
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: displayWidth(context)*0.03,
                fontFamily: appPoppinFont
            ),
            maxLines: 3,
            softWrap: true,
          ),
        ],
      ),
    );
  }
}