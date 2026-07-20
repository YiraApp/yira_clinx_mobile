import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/common_widgets/custom_border_button.dart';
import '../../../../core/constants/constants.dart';

class ReusableTestCard extends StatelessWidget {
  final String title;
  final String doctorName;
  final String date;
  final List<String> parameters;
  final String statusText;
  final bool isAbnormal;
  final VoidCallback? onViewDetails;
  final VoidCallback? onDownload;

  const ReusableTestCard({
    super.key,
    required this.title,
    required this.doctorName,
    required this.date,
    required this.parameters,
    required this.statusText,
    this.isAbnormal = false,
    this.onViewDetails,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color statusColor = isAbnormal
        ? (isDark ? Colors.redAccent : Colors.red.shade700)
        : (isDark ? Colors.greenAccent : Colors.green.shade700);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                ),
                child: Icon(
                  Icons.science_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText(
                      title,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.w600,
                        fontSize: displayWidth(context)*0.035,
                        // color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CommonText(
                      "Dr. $doctorName • $date",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: displayWidth(context)*0.028,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAbnormal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:  CommonText(
                    "Urgent",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      color: Colors.white,
                      fontSize: displayWidth(context)*0.026,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(
                thickness: 1.5,color: Colors.grey.withOpacity(0.1)
            ),
          ),

          CommonText(
            "Summary:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: displayWidth(context)*0.032,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: parameters.map((param) => _ParameterChip(label: param)).toList(),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAbnormal ? Icons.error_outline : Icons.check_circle_outline,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  CommonText(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: displayWidth(context)*0.03,
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  CommonBorderButton(
                    height: 35,
                    icon:  Icons.file_download_outlined,
                    text: 'Download', onPressed: () {  },
                  ),
                  const SizedBox(width: 8),
                  CommonBorderButton(
                    height: 35,
                    text: "View Details",
                    onPressed: onViewDetails ?? () {},
                  ),


                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParameterChip extends StatelessWidget {
  final String label;
  const _ParameterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: CommonText(
        label,
        style: TextStyle(
          fontSize: displayWidth(context)*0.028,
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
        ),
      ),
    );
  }
}