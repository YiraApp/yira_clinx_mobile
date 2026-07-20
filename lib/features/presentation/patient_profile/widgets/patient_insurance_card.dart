
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import 'metric_tile_item.dart';
import 'patient_info_card.dart';

class PatientInsuranceCard extends StatelessWidget {
  final InsuranceEntity patient;
  final bool isTab;
  const PatientInsuranceCard({super.key, required this.patient, required  this.isTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PatientInfoCard(
      isTab: isTab,
      title: 'Insurance',
      titleIcon: Icons.shield_outlined,
      child: (patient.policyName != null && patient.policyNumber != null)
          ? Column(
        children: [
          MetricTileItem(
            isTab: isTab,
            icon: Icons.verified_user_outlined,
            label: 'Policy Name',
            value: patient.policyName ?? 'N/A',
            accentColor: Colors.blue,
          ),
          _buildDivider(isDark),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.tag,
            label: 'Policy Number',
            value: patient.policyNumber ?? 'N/A',
            accentColor: Colors.blueGrey,
          ),
        ],
      )
          : Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900]!.withOpacity(0.5) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(color: isDark ? Colors.grey[850]! : const Color(0xFFE9ECEF)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                shape: BoxShape.circle,
                boxShadow: !isDark
                    ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Icon(
                Icons.verified_user_outlined,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No insurance details linked.',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
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
}