
import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';

class AIInsightItem extends StatelessWidget {
  final String title, desc, tag;
  final Color color;
  final String? val;

  const AIInsightItem({
    super.key,
    required this.title,
    required this.desc,
    required this.tag,
    required this.color,
    this.val,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.05 : 0.02),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CommonText(

                  title,
                  maxLines: null,
                  softWrap: true,
                  style:  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context)*0.028,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CommonText(
                tag.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontFamily: appPoppinFont,
                  fontSize: displayWidth(context)*0.02,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (val != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommonText(
                    "Value: $val",
                    style:  TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context)*0.025,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          CommonText(
            desc,
            maxLines: 4,
            softWrap: true,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context)*0.03,
              height: 1.5,
              // color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}