import 'package:yiraclinics/core/widgets/ios_icons.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import 'metric_tile_item.dart';
import 'patient_info_card.dart';
import 'record_tab_ui.dart';

class PatientInsuranceCard extends StatelessWidget {
  final InsuranceEntity patient;
  final bool isTab;
  const PatientInsuranceCard({super.key, required this.patient, required  this.isTab});

  @override
  Widget build(BuildContext context) {
    return PatientInfoCard(
      isTab: isTab,
      title: 'Insurance',
      titleIcon: IosIcons.shield_outlined,
      child: (patient.policyName != null && patient.policyNumber != null)
          ? Column(
        children: [
          MetricTileItem(
            isTab: isTab,
            icon: IosIcons.verified_user_outlined,
            label: 'Policy Name',
            value: patient.policyName ?? 'N/A',
            accentColor: const Color(0xFF2563EB),
          ),
          const RecordDivider(indent: 30),
          MetricTileItem(
            isTab: isTab,
            icon: IosIcons.tag,
            label: 'Policy Number',
            value: patient.policyNumber ?? 'N/A',
            accentColor: Colors.blueGrey,
          ),
        ],
      )
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: RecordEmptyState(icon: IosIcons.verified_user_outlined, title: 'No insurance details linked.'),
            ),
    );
  }
}
