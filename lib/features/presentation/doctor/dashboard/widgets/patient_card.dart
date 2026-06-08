// presentation/widgets/patient_card.dart
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/common_widgets/common_text.dart';
import '../../../../../core/constants/constants.dart';
import '../../../../domain/entities/dashboard/patient_entity.dart';

class PatientCard extends StatelessWidget {
  final PatientEntity patient;
  final VoidCallback onTap;
  final bool isTab;
  const PatientCard({super.key, required this.patient, required this.onTap, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: fieldSpace),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor: Colors.white,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: .spaceBetween,
              crossAxisAlignment: .start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius:isTab?  displayWidth(context) * 0.03: displayWidth(context) * 0.06,
                      backgroundColor: isDark
                          ? Colors.blue.withOpacity(0.2)
                          : const Color(0xFFDBEAFE),
                      child: CommonText(
                        patient.name.substring(0, 2).toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: appPoppinFont,
                          fontSize:isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.035,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText(
                          patient.name,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w600,
                            fontSize: isTab?  displayWidth(context) * 0.02: displayWidth(context) * 0.036,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        CommonText(
                          "${patient.id} | ${patient.age}y | ${patient.gender}",
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: appPoppinFont,
                            fontSize:isTab?  displayWidth(context) * 0.018:  displayWidth(context) * 0.029,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                _buildStatusBadge(context, patient.status,isTab),
              ],
            ),
            const SizedBox(height: 12),
            CommonText(
              patient.condition,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontFamily: appPoppinFont,
                fontSize:isTab?  displayWidth(context) * 0.018:  displayWidth(context) * 0.03,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildInfoItem(context, "Visits: ", "${patient.visits}",isTab),
                const SizedBox(width: 16),
                _buildInfoItem(context, "Last: ", patient.lastVisit,isTab),
              ],
            ),
            if (patient.allergy.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    CommonText(
                      "Allergic: ${patient.allergy}",
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: appPoppinFont,
                        fontSize:isTab?  displayWidth(context) * 0.018:  displayWidth(context) * 0.025,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value,bool isTab) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Colors.grey,
          fontSize:isTab?  displayWidth(context) * 0.02:  displayWidth(context) * 0.03,
          fontFamily: appPoppinFont,
        ),
        children: [
          TextSpan(text: label),
          TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: appPoppinFont,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
              fontSize:isTab?  displayWidth(context) * 0.018:  displayWidth(context) * 0.028,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status,bool isTab) {
    Color color;
    switch (status.toUpperCase()) {
      case "CRITICAL":
        color = Colors.red;
        break;
      case "ACTIVE":
        color = Colors.green;
        break;
      case "RECOVERING":
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CommonText(
        status,
        style: TextStyle(
          fontFamily: appPoppinFont,
          color: color,
          fontSize:isTab?  displayWidth(context) * 0.018:  displayWidth(context) * 0.025,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
