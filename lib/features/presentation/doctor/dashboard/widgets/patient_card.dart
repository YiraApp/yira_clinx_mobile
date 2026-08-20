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

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFFD97706),
      const Color(0xFF0891B2),
      const Color(0xFFDB2777),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarClr = _avatarColor(patient.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Avatar + Name + Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with gradient
                Container(
                  width: isTab ? displayWidth(context) * 0.06 : displayWidth(context) * 0.115,
                  height: isTab ? displayWidth(context) * 0.06 : displayWidth(context) * 0.115,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        avatarClr,
                        avatarClr.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: CommonText(
                    patient.name.isNotEmpty
                        ? (patient.name.length >= 2
                            ? patient.name.substring(0, 2).toUpperCase()
                            : patient.name.toUpperCase())
                        : 'PT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.036,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + subtext
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonText(
                        patient.name,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w600,
                          fontSize: isTab ? displayWidth(context) * 0.019 : displayWidth(context) * 0.037,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      CommonText(
                        "${patient.id} · ${patient.age}y · ${patient.gender}",
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? displayWidth(context) * 0.015 : displayWidth(context) * 0.028,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context, patient.status, isTab),
              ],
            ),

            // Condition
            if (patient.condition.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CommonText(
                  patient.condition,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.03,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Bottom row: Info chips + allergy
            Row(
              children: [
                _buildInfoChip(context, Icons.repeat_rounded, "${patient.visits} visits", isTab, isDark),
                const SizedBox(width: 8),
                if (patient.lastVisit.isNotEmpty)
                  _buildInfoChip(context, Icons.access_time_rounded, patient.lastVisit, isTab, isDark),
                const Spacer(),
                if (patient.allergy.isNotEmpty)
                  _buildAllergyChip(context, patient.allergy, isTab, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text, bool isTab, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTab ? 13 : 12, color: isDark ? Colors.white54 : Colors.grey.shade500),
          const SizedBox(width: 4),
          CommonText(
            text,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.026,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyChip(BuildContext context, String allergy, bool isTab, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.12) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 12),
          const SizedBox(width: 4),
          CommonText(
            allergy,
            style: TextStyle(
              color: Colors.red.shade400,
              fontFamily: appPoppinFont,
              fontSize: isTab ? displayWidth(context) * 0.013 : displayWidth(context) * 0.024,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status, bool isTab) {
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
      case "INACTIVE":
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: CommonText(
        status,
        style: TextStyle(
          fontFamily: appPoppinFont,
          color: color,
          fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.024,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
