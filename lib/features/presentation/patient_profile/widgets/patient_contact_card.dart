
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import 'metric_tile_item.dart';
import 'patient_info_card.dart';

class PatientContactCard extends StatelessWidget {
  final ContactInformationEntity patient;
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
            value: patient.phone ?? '',
            accentColor: Colors.blue,
          ),
          _buildDivider(isDark),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.alternate_email_rounded,
            label: 'Email Address',
            value: patient.emailAddress ?? '',
            accentColor: Colors.teal,
          ),
          _buildDivider(isDark),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.map_outlined,
            label: 'Residential Address',
            value: patient.residentialAddress ?? '',
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
    final name = (patient.emergencyContact?.name ?? '').trim();
    final phone = (patient.emergencyContact?.phone ?? '').trim();
    final relation = (patient.emergencyContact?.relationship ?? '').trim();
    // No contact on file: a quiet grey note, not a red alert with a stray "•".
    final hasContact = name.isNotEmpty || phone.isNotEmpty;
    final Color tone = hasContact ? Colors.red : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final bannerBg = hasContact ? (isDark ? Colors.red.withOpacity(0.08) : Colors.red.withOpacity(0.1)) : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC));
    final bannerBorder = hasContact ? (isDark ? Colors.red.withOpacity(0.4) : Colors.red.withOpacity(0.01)) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0));
    final iconBg = hasContact ? (isDark ? Colors.red.withOpacity(0.06) : Colors.red.withOpacity(0.1)) : (isDark ? Colors.white10 : const Color(0xFFF1F5F9));
    final detail = hasContact
        ? [name, if (relation.isNotEmpty) '($relation)', if (phone.isNotEmpty) '• $phone'].where((e) => e.isNotEmpty).join(' ')
        : 'Not added by the patient';

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
            child: Icon(hasContact ? Icons.phone_in_talk_rounded : Icons.person_off_outlined, color: tone, size: 14),
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
                    color: tone,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize:isTab?  displayWidth(context) * 0.02:  displayWidth(context) * 0.032,
                    fontWeight: hasContact ? FontWeight.w600 : FontWeight.w500,
                    color: tone,
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