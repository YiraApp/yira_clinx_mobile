
import 'package:flutter/material.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/prescriptions/prescription_item.dart';

class DetailedPrescriptionExpandableCard extends StatefulWidget {
  final MedicationItem item;

  const DetailedPrescriptionExpandableCard({
    super.key,
    required this.item,
  });

  @override
  State<DetailedPrescriptionExpandableCard> createState() => _DetailedPrescriptionExpandableCardState();
}

class _DetailedPrescriptionExpandableCardState extends State<DetailedPrescriptionExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final String doseAmount = widget.item.dosage ?? '20';
    final String frequencyStr = widget.item.frequency ?? '0-1-0 (Afternoon)';
    final String durationStr = widget.item.duration ?? '5 days';
    final String visualSummary = '$doseAmount • $frequencyStr • $durationStr';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade200.withOpacity(0.6),
          width: 1.2,
        ),
        boxShadow: !isDark
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusBarColor.withOpacity(isDark ? 0.08 : 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_information,
                      color: isDark ?  iconDarkColor : const Color(0xFF2E7D32),
                      size: isTab ? 24 : 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText(
                          widget.item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: displayWidth(context) * (isTab ? 0.022 : 0.035),
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : adaptiveTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CommonText(
                          visualSummary,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: displayWidth(context) * (isTab ? 0.016 : 0.03),
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(sizeFactor: animation, axisAlignment: -1.0, child: child);
            },
            child: _isExpanded
                ? Padding(
              key: const ValueKey('expanded_card_contents'),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade100, height: 1),
                  const SizedBox(height: 14),
                  CommonText(
                    'ROUTE',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context) * (isTab ? 0.014 : 0.026),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CommonText(
                    widget.item.route ?? 'Oral',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context) * (isTab ? 0.018 : 0.034),
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade300 : borderSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CommonText(
                    'INSTRUCTIONS',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context) * (isTab ? 0.014 : 0.026),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CommonText(
                    'Personal & Clinical Data: If you are a patient, access your medical records directly through your local healthcare provider, or check health insurance portals (such as those tied to Ayushman Bharat or local state programs) for digital health records.',
                    maxLines: 10,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context) * (isTab ? 0.016 : 0.031),
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: isDark ? Colors.grey.shade400 : dialogueSubTextColor,
                    ),
                  ),
                ],
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}