
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import 'metric_tile_item.dart';
import 'patient_info_card.dart';

class PatientContactCard extends StatelessWidget {
  final PatientProfileEntity patient;
  final bool isTab;
  const PatientContactCard({super.key, required this.patient,required this.isTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PatientInfoCard(
      isTab: isTab,
      title: 'Contact Information',
      titleIcon: Icons.perm_contact_calendar_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetricTileItem(
            isTab: isTab,
            icon: Icons.phone_android_rounded,
            label: 'Phone',
            value: patient.phone,
            accentColor: Colors.blue,
          ),
          _buildDivider(isDark),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.alternate_email_rounded,
            label: 'Email Address',
            value: patient.email,
            accentColor: Colors.teal,
          ),
          _buildDivider(isDark),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.map_outlined,
            label: 'Residential Address',
            value: patient.address,
            accentColor: Colors.indigo,
          ),
          const SizedBox(height: 24),
          _buildEmergencyBanner(context,isTab),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.grey[850] : const Color(0xFFF1F3F5),
        indent: 52,
      ),
    );
  }

  Widget _buildEmergencyBanner(BuildContext context,bool isTab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark ? Colors.red.withOpacity(0.08) : Colors.red.withOpacity(0.1);
    final bannerBorder = isDark ? Colors.red.withOpacity(0.4) : Colors.red.withOpacity(0.01);
    final iconBg = isDark ? Colors.red.withOpacity(0.06) : Colors.red.withOpacity(0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: bannerBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 14),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize:isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.024,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${patient.emergencyContactName} • ${patient.emergencyContactPhone}',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize:isTab?  displayWidth(context) * 0.02:  displayWidth(context) * 0.032,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}