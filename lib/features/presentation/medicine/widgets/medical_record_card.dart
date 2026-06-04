
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import '../../../../core/common_widgets/custom_border_button.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';

class MedicalRecordCard extends StatelessWidget {
  final String title;
  final String formattedDate;
  final String doctorName;
  final String status;
  final String chiefComplaint;
  final String diagnosis;
  final String vitalsSummary;
  final VoidCallback onDetailsPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onEditPressed;

  const MedicalRecordCard({
    super.key,
    required this.title,
    required this.formattedDate,
    required this.doctorName,
    required this.status,
    required this.chiefComplaint,
    required this.diagnosis,
    required this.vitalsSummary,
    required this.onDetailsPressed,
    required this.onDeletePressed, required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2),width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFE2E8F0).withOpacity(0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(fieldBorderRadius)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(fieldBorderRadius/2),
                  ),
                  child: const Icon(Icons.description, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CommonText(
                              title,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.042,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                              onTap: onEditPressed,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(Icons.edit_outlined, color: Colors.grey.shade600, size: 18),
                              )),
                        ],
                      ),
                      const SizedBox(height: 2),
                      CommonText(
                        "$formattedDate | $doctorName",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          color: Colors.grey.shade600,
                          fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.029,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CommonText(
                          status,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: isTab ? displayWidth(context) * 0.012 : displayWidth(context) * 0.022,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: isDark ? darkModeInnerCardColor : Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDynamicRow(context, "Chief Complaint", chiefComplaint, isTab),
                const SizedBox(height: 12),
                _buildDynamicRow(context, "Diagnosis", diagnosis, isTab),
                const SizedBox(height: 16),

                // Blue Highlight Vitals Bar Strip matching design standard
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CommonText(
                        "Vitals: ",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.bold,
                          fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.032,
                        ),
                      ),
                      SizedBox(width: 10,),
                      Expanded(
                        child: CommonText(
                          vitalsSummary,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600,
                            fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.032,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isDark ? Colors.transparent : Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(fieldBorderRadius)),
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onDeletePressed,
                  icon: Container(
                    padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(width: 1,color: Colors.red.withOpacity(0.5))
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18)),
                ),
                const SizedBox(width: 8),
                CommonBorderButton(height: 35, icon: Icons.remove_red_eye_outlined,text: 'View Details', onPressed: () {}),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDynamicRow(BuildContext context, String titlePrefix, String bodyText, bool isTab) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: displayWidth(context)/3,
          child: Container(
            padding: EdgeInsets.only(top: 2),
            child: CommonText(
              titlePrefix,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w600,
                fontSize: isTab ? displayWidth(context) * 0.015 : displayWidth(context) * 0.032,
              ),
            ),
          ),
        ),
        Text(': ',
            style: TextStyle(
              color: Theme.of(context)
                  .brightness ==
                  Brightness.dark
                  ? Colors.white
                  : Colors.black,
            )),
        Flexible(
          child: Container(
            padding: EdgeInsets.only(top: 2),
            child: CommonText(
              bodyText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: TextStyle(
                fontFamily: appPoppinFont,
                color: Colors.grey.shade600,
                fontSize: isTab ? displayWidth(context) * 0.015 : displayWidth(context) * 0.032,
              ),
            ),
          ),
        ),
      ],
    );
  }
}